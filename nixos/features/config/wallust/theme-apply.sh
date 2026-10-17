#!/usr/bin/env bash
# Apply a curated wallust colorscheme by name (or path) and reload every app.
#
# wallust `cs` writes templates but does NOT run [hooks] (only `run` does), so the
# reloads are performed here. Quickshell needs no reload, Theme.qml reads
# colors.json via a watched FileView and restyles live.
#
# GTK is OPTION B: the hand-made custom GTK 3/4 themes are preserved and switched
# from ~/.config/colorschemes/<name>/ (symlink the per-theme gtk-4.0 + set the GTK
# theme name), GTK is NOT recolored by wallust templates. A scheme with no
# gtk-theme file of its own uses adw-gtk3-dark.
#
# Usage: theme-apply.sh <name|/path/to/scheme.json>
#   names resolve to ~/.config/wallust/colorschemes/<name>.json

set -uo pipefail

# GTK3 apps on native Wayland read org.gnome.desktop.interface.gtk-theme from
# GSettings/dconf (XSettings only reaches X11/XWayland). gsettings needs that
# schema on its search path; until gsettings-desktop-schemas lands in the system
# profile, locate it in the store so theme switches still reach Wayland GTK3 apps.
if ! gsettings list-schemas 2>/dev/null | grep -qx org.gnome.desktop.interface; then
    for d in /nix/store/*gsettings-desktop-schemas*/share/gsettings-schemas/*/glib-2.0/schemas \
             /nix/store/*gsettings-desktop-schemas*/share/glib-2.0/schemas; do
        if [ -f "$d/gschemas.compiled" ]; then
            export GSETTINGS_SCHEMA_DIR="$d${GSETTINGS_SCHEMA_DIR:+:$GSETTINGS_SCHEMA_DIR}"
            break
        fi
    done
fi

arg="${1:?usage: theme-apply.sh <name|scheme.json>}"

scheme="$arg"
[ -f "$scheme" ] || scheme="$HOME/.config/wallust/colorschemes/${arg}.json"
if [ ! -f "$scheme" ]; then
    notify-send "Theme" "No colorscheme: $arg" -u critical 2>/dev/null || true
    echo "no colorscheme: $arg" >&2
    exit 1
fi
name="$(basename "$scheme" .json)"

wallust cs "$scheme" -s || { echo "wallust cs failed" >&2; exit 1; }

# --- sync the shell's Config (theme) + auto-apply this theme's last-used wallpaper ---
# Keeps config.json in sync regardless of entry point (CLI or in-shell switcher),
# and restores the wallpaper last chosen for this theme (else its first one).
cfg="$HOME/.config/quickshell/config.json"
state="$HOME/.config/quickshell/wallpaper-state"
wpdir="$HOME/.config/colorschemes/$name/wallpapers"
wp=""
[ -f "$state" ] && wp="$(awk -F'\t' -v t="$name" '$1==t{print $2; exit}' "$state")"
if [ -z "$wp" ] || [ ! -f "$wp" ]; then
    wp="$(find "$wpdir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort | head -1)"
fi
# Write the theme (and this theme's wallpaper, if we found one) into config.json with
# python3, NOT jq. jq isn't guaranteed to be installed, and when it went missing this
# silently no-op'd, so the theme switcher looked dead. python3 is basically always there.
# Single writer: the in-shell switcher no longer touches config.json, so no write race.
if command -v python3 >/dev/null 2>&1 && [ -f "$cfg" ]; then
    if python3 - "$cfg" "$name" "$wp" <<'PY'
import json, os, sys
cfg, name, wp = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    d = json.load(open(cfg))
except Exception:
    d = {}
d["theme"] = name
if wp and os.path.isfile(wp):
    d["wallpaper"] = wp
tmp = cfg + ".tmp"
with open(tmp, "w") as f:
    json.dump(d, f, indent=4)
os.replace(tmp, cfg)   # atomic
PY
    then
        if [ -n "$wp" ] && [ -f "$wp" ]; then
            "$HOME/.config/wallust/wallpaper-record.sh" "$name" "$wp" 2>/dev/null || true
        fi
    fi
fi

# --- non-GTK reloads (cs skips wallust [hooks]) ---
hyprctl reload    >/dev/null 2>&1 || true
pkill -USR1 kitty 2>/dev/null      || true
# foot: new windows pick up colors. vesktop: hot-reloads CSS. quickshell: live FileView.

# --- GTK (option B): switch the matching custom GTK 3/4 theme, else adw-gtk3-dark ---
# Both toolkits load the same base Colloid theme plus the same per-scheme accent
# overlay (wallust slot12), so GTK3 and GTK4 apps render identically:
#   GTK3: named theme (via XSettings/dconf) + ~/.config/gtk-3.0/gtk.css, the
#         Nix-managed stub @import 'colors.css'; @import 'scheme.css';
#   GTK4/libadwaita ignores the theme name, so ~/.config/gtk-4.0/gtk.css (also a
#         Nix-managed stub) imports the theme + overlay symlinked below.
csdir="$HOME/.config/colorschemes/$name"
# A scheme with no gtk-theme file of its own falls back to adw-gtk3-dark, so it
# still gets a defined GTK look instead of inheriting whatever dconf was left on.
theme_name="adw-gtk3-dark"
[ -f "$csdir/gtk-theme" ] && theme_name="$(cat "$csdir/gtk-theme")"

# GTK3: accent overlay on top of the named theme; drop stale extras.
rm -f "$HOME/.config/gtk-3.0/gtk-dark.css"
rm -rf "$HOME/.config/gtk-3.0/assets"
if [ -f "$csdir/gtk-3.0/gtk.css" ]; then
    ln -sf "$csdir/gtk-3.0/gtk.css" "$HOME/.config/gtk-3.0/scheme.css" 2>/dev/null || true
fi

# GTK4: base theme + the identical per-scheme accent overlay, both imported by the
# Nix-managed gtk-4.0/gtk.css stub. Keep the theme's assets alongside for url()s.
mkdir -p "$HOME/.config/gtk-4.0"
rm -f "$HOME/.config/gtk-4.0"/{theme.css,theme-dark.css,scheme.css}
rm -rf "$HOME/.config/gtk-4.0"/{assets,windows-assets,gtk-Light.css,gtk-Dark.css}
if [ -d "$HOME/.themes/$theme_name/gtk-4.0" ]; then
    ln -sfn "$HOME/.themes/$theme_name/gtk-4.0/assets"       "$HOME/.config/gtk-4.0/assets"
    ln -sfn "$HOME/.themes/$theme_name/gtk-4.0/gtk.css"      "$HOME/.config/gtk-4.0/theme.css"
    ln -sfn "$HOME/.themes/$theme_name/gtk-4.0/gtk-dark.css" "$HOME/.config/gtk-4.0/theme-dark.css"
fi
[ -f "$csdir/gtk-4.0/gtk.css" ] && ln -sfn "$csdir/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/scheme.css"
# Import stubs are declared in theming.nix; (re)create them here too so the new
# layout applies immediately, replacing the old gtk.css -> ~/.themes/... symlink.
for stub in gtk.css gtk-dark.css; do
    target="$HOME/.config/gtk-4.0/$stub"
    case "$(readlink "$target" 2>/dev/null)" in
        "$HOME/.themes/"*) rm -f "$target" ;;
    esac
    [ -e "$target" ] || printf "@import 'theme%s';\n@import 'scheme.css';\n" "${stub#gtk}" > "$target"
done

if [ -n "$theme_name" ]; then
    gsettings set org.gnome.desktop.interface gtk-theme "$theme_name" 2>/dev/null || true
fi

# GTK3 also reads its theme name from XSettings (xsettingsd) on X11/XWayland,
# and nwg-look otherwise overwrites this behind our back. Keep xsettingsd in
# sync and HUP it so X11 apps track the same theme as native-Wayland GTK3.
xsconf="$HOME/.config/xsettingsd/xsettingsd.conf"
if [ -f "$xsconf" ]; then
    tmp="$(mktemp)"
    { grep -v '^Net/ThemeName' "$xsconf" 2>/dev/null || true; printf 'Net/ThemeName "%s"\n' "$theme_name"; } > "$tmp"
    mv "$tmp" "$xsconf"
    pkill -HUP xsettingsd 2>/dev/null || true
fi

# Color-scheme hint: a scheme may carry an optional 'gtk-color-scheme' file
# (e.g. e-ink is light). Defaults to prefer-dark for the curated dark themes.
# Toggle away and back when we're already on the desired value so running GTK
# apps live-reload their CSS; otherwise just write the desired value once.
gtk_desired="prefer-dark"
[ -f "$csdir/gtk-color-scheme" ] && gtk_desired="$(cat "$csdir/gtk-color-scheme")"
gtk_current="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)"
if [[ "$gtk_current" == "'$gtk_desired'" ]]; then
    gtk_other="prefer-light"
    [[ "$gtk_desired" == 'prefer-light' ]] && gtk_other="prefer-dark"
    gsettings set org.gnome.desktop.interface color-scheme "$gtk_other" 2>/dev/null || true
fi
gsettings set org.gnome.desktop.interface color-scheme "$gtk_desired" 2>/dev/null || true

# --- spicetify (option B: curated Sleek color schemes; best-effort name match) ---
if command -v spicetify >/dev/null 2>&1; then
    sptheme="$(spicetify config current_theme 2>/dev/null)"
    ini="$HOME/.config/spicetify/Themes/${sptheme}/color.ini"
    for cand in "$name" "${name}-dark"; do
        if [ -f "$ini" ] && grep -q "^\[${cand}\]" "$ini"; then
            spicetify config color_scheme "$cand" >/dev/null 2>&1 || true
            spicetify refresh                     >/dev/null 2>&1 || true
            break
        fi
    done
fi

# --- nvim (option B): write the theme name to the cache file nvim watches ---
nvim_theme="$name"
[ -f "$csdir/nvim-theme" ] && nvim_theme="$(cat "$csdir/nvim-theme")"
printf "%s" "$nvim_theme" > "$HOME/.cache/nvim-dynamite-theme"

# --- vscodium: set the colour theme ---
# Not jq: settings.json is JSONC (trailing comma), which jq refuses to parse, so
# the old jq call failed silently on every switch. vscodium-apply.sh edits the
# theme value in place (same inode, so a running VSCodium window's settings
# watcher fires and repaints live) and leaves the rest of the file untouched.
[ -x "$HOME/.config/colorschemes/vscodium-apply.sh" ] && \
    "$HOME/.config/colorschemes/vscodium-apply.sh" "$name" >/dev/null 2>&1 || true

