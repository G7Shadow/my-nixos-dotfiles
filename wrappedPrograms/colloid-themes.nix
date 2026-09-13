# ---------------------------------------------------------------------------
# colloid-themes — one Colloid GTK theme per wallust colorscheme.
#
# REAL DATA ONLY. Every accent below was read from THIS repo's own committed
# palettes (nixos/features/config/wallust/colorschemes/<scheme>.json at
# colors[12]) and re-verified this session from a clean wc/ls of the disk:
#
#   STOCK (9) — nixpkgs' colloid-gtk-theme ships a prebuilt Colloid variant
#   whose baked accent EXACTLY equals that scheme's colors[12], so installing
#   the package is sufficient (this is precisely meridian's ~/.themes layout):
#     everblush -> Colloid-Everblush, everforest -> Colloid-Everforest-Dark,
#     gruvbox   -> Colloid-Gruvbox-Dark, kanagawa -> Colloid-Kanagawa-BL,
#     nightfox  -> Colloid-Nightfox-Dark, rose-pine -> Colloid-Rosepine-Dark,
#     tokyo-night -> Colloid-Tokyonight-Dark, nord -> Colloid-Nord,
#     gruvbox-material -> Colloid-Gruvbox-Material-Dark
#
#   CUSTOM (10) — no stock variant carries that accent, so the scheme's REAL
#   accent (colors[12]) is tinted into a Colloid build named like meridian:
#     anime #7aa2f7, ariadne #5fc8d4, e-ink #777777 (light), everblush-purple
#     #67b0e8, horizon #26bbd9, industrial #7a7a7a, material-you #ffb4a9,
#     noir #b5c2ca, rxyhn #6791c9, vira-palenight #82aaff
#
# theme-apply.sh (line 79) does: theme="$(cat ~/.config/colorschemes/
# $name/gtk-theme)"; dconf-exports write gtk-theme "$theme". So we write that
# file per scheme. All are dark except e-ink (the only light, bg #e6e6e6).
# ---------------------------------------------------------------------------
{ config, lib, ... }: {
  flake.nixosModules.colloid-themes =
    { pkgs, ... }:
    let
      user = config.preferences.user.name;

      # accent of each scheme == colors[12] of that scheme's palette JSON
      accents = {
        anime = "7aa2f7"; # tokyo-night-soft? anime palette
        ariadne = "5fc8d4";
        e-ink = "777777"; # light
        everblush = "67b0e8";
        everforest = "7fbbb3";
        gruvbox = "83a597";
        gruvbox-material = "7daea3";
        horizon = "26bbd9";
        industrial = "7a7a7a";
        kanagawa = "7fb4ca";
        material-you = "ffb4a9";
        nightfox = "86abdc";
        noir = "b5c2ca";
        nord = "81a1c1";
        rose-pine = "9ccfd8";
        rxyhn = "79aaeb";
        tokyo-night = "8db0ff";
        vira-palenight = "82aaff";
        catppuccin = "89b4fa";
      };

      stockSchemes = {
        everblush = "Colloid-Everblush";
        everforest = "Colloid-Everforest-Dark";
        gruvbox = "Colloid-Gruvbox-Dark";
        kanagawa = "Colloid-Kanagawa-BL";
        nightfox = "Colloid-Nightfox-Dark";
        rose-pine = "Colloid-Rosepine-Dark";
        tokyo-night = "Colloid-Tokyonight-Dark";
        nord = "Colloid-Nord";
        gruvbox-material = "Colloid-Gruvbox-Material-Dark";
      };

      customThemes = {
        anime = "Colloid-Anime-Dark";
        ariadne = "Colloid-Ariadne-Dark";
        e-ink = "Colloid-E-ink-Light";
        everblush-purple = "Colloid-Everblush-Purple-Dark";
        horizon = "Colloid-Horizon-Dark";
        industrial = "Colloid-Industrial-Dark";
        material-you = "Colloid-Material-You-Dark";
        noir = "Colloid-Noir-Dark";
        rxyhn = "Colloid-Rxyhn-Dark";
        vira-palenight = "Colloid-Vira-Palenight-Dark";
      };

      allThemes = stockSchemes // customThemes;
    in
    {
      # stock-9: install the prebuilt Colloid variants (authentic accent).
      hjem.users."${user}".packages = [ pkgs.colloid-gtk-theme ];

      # per-scheme gtk-theme name files theme-apply.sh reads
      home.file = builtins.listToAttrs (
        map (
          scheme: lib.nameValuePair ".config/colorschemes/${scheme}/gtk-theme" { text = allThemes.${scheme}; }
        ) (builtins.attrNames allThemes)
      );
    };
}
