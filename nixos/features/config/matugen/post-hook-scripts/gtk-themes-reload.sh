#!/usr/bin/env bash
# Bounce org.gnome.desktop.interface color-scheme away and back so running GTK4 /
# libadwaita apps (nautilus) re-read gtk.css, which GTK4 does not watch.
# NOT a theme switch: the final value always equals the initial one.
#
# dconf, not gsettings: the `gsettings` first on PATH is hjem's unwrapped glib and
# fails with "No schemas installed", silently no-opping this hook. dconf comes from
# the system profile (programs.dconf.enable) and needs no schemas.
set -uo pipefail

key=/org/gnome/desktop/interface/color-scheme
current="$(dconf read "$key" 2>/dev/null || true)"

if [[ "$current" == "'prefer-dark'" ]]; then
    dconf write "$key" "'prefer-light'" || true
    dconf write "$key" "'prefer-dark'" || true
else
    dconf write "$key" "'prefer-dark'" || true
    dconf write "$key" "'prefer-light'" || true
fi
