#!/usr/bin/env bash
# Apply a curated wallust colorscheme by name (or path) and reload every app.
#
# wallust `cs` writes templates but does NOT run [hooks] (only `run` does), so the
# reloads are performed here. Quickshell needs no reload, Theme.qml reads
# colors.json via a watched FileView and restyles live.
#
# GTK is OPTION B: the hand-made custom GTK 3/4 themes are preserved and switched
# from ~/.config/colorschemes/<name>/ (symlink the per-theme gtk-4.0 + set the GTK
# theme name), GTK is NOT recolored by wallust templates.
#
# Usage: theme-apply.sh <name|/path/to/scheme.json>
#   names resolve to ~/.config/wallust/colorschemes/<name>.json

set -uo pipefail
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
if command -v jq >/dev/null 2>&1 && [ -f "$cfg" ]; then
    tmp="$(mktemp)"
    if [ -n "$wp" ] && [ -f "$wp" ]; then
        jq --arg t "$name" --arg w "$wp" '.theme=$t | .wallpaper=$w' "$cfg" >"$tmp" && mv "$tmp" "$cfg" || rm -f "$tmp"
        "$HOME/.config/wallust/wallpaper-record.sh" "$name" "$wp" 2>/dev/null || true
    else
        jq --arg t "$name" '.theme=$t' "$cfg" >"$tmp" && mv "$tmp" "$cfg" || rm -f "$tmp"
    fi
fi

# --- non-GTK reloads (cs skips wallust [hooks]) ---
hyprctl reload    >/dev/null 2>&1 || true
pkill -USR1 kitty 2>/dev/null      || true
# foot: new windows pick up colors. vesktop: hot-reloads CSS. quickshell: live FileView.

# --- GTK: set gtk-theme-name in settings.ini (nwg-look / GTK native) ---
csdir="$HOME/.config/colorschemes/$name"
if [ -f "$csdir/gtk-theme" ]; then
    gtkname="$(cat "$csdir/gtk-theme")"
    # gtk-3.0 settings.ini
    if grep -q "^gtk-theme-name" "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null; then
        sed -i "s|^gtk-theme-name=.*|gtk-theme-name=$gtkname|" "$HOME/.config/gtk-3.0/settings.ini"
    else
        echo "gtk-theme-name=$gtkname" >> "$HOME/.config/gtk-3.0/settings.ini"
    fi
    # gtkrc (GTK 2)
    if [ -f "$HOME/.config/gtkrc" ] && grep -q '^gtk-theme-name=' "$HOME/.config/gtkrc" 2>/dev/null; then
        sed -i "s|^gtk-theme-name=.*|gtk-theme-name=\"$gtkname\"|" "$HOME/.config/gtkrc"
    fi
    # xsettingsd: live-reload running GTK apps
    xscfg="$HOME/.config/xsettingsd/xsettingsd.conf"
    if [ -f "$xscfg" ]; then
        sed -i "s|^Net/ThemeName.*|Net/ThemeName \"$gtkname\"|" "$xscfg"
        pkill -HUP xsettingsd 2>/dev/null || true
    fi
fi

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

# --- neovim: write theme name to cache file for lazy.lua + autocmds.lua ---
nvim_theme="$name"
[ -f "$csdir/nvim-theme" ] && nvim_theme="$(cat "$csdir/nvim-theme")"
printf "%s" "$nvim_theme" > "$HOME/.cache/nvim-dynamite-theme"

# --- vscodium: set workbench.colorTheme via sed (settings.json has trailing commas, jq can't parse) ---
vscfg="$HOME/.config/VSCodium/User/settings.json"
if [ -f "$csdir/vscodium-theme" ] && [ -f "$vscfg" ]; then
    vsname="$(cat "$csdir/vscodium-theme")"
    if grep -q '"workbench.colorTheme"' "$vscfg"; then
        sed -i 's|"workbench.colorTheme": "[^"]*"|"workbench.colorTheme": "'"$vsname"'"|' "$vscfg"
    else
        sed -i '1s|{|{"workbench.colorTheme": "'"$vsname"'",\n|' "$vscfg"
    fi
fi

