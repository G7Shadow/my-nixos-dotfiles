#!/usr/bin/env bash


THEME_DIR="$HOME/.config/rofi/themes/config"

rofi -show drun \
     -theme "$THEME_DIR/colors.rasi" \
     -theme-str "@import \"$THEME_DIR/config.rasi\""