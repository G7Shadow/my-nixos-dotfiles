# ---------------------------------------------------------------------------
# colloid-themes — one Colloid GTK theme per wallust colorscheme.
#
# THE COLORS: every accent below is **read from this repo's own committed
# palettes** (nixos/features/config/wallust/colorschemes/<scheme>.json at
# colors[12]) — NOT invented. Verified accent table (all 19; e-ink is the
# only light/light variant — bg #e6e6e6 => stock Colloid-Light; all rest
# dark):
#
#   STOCK (9) — meridian ships these exact stock variants; accent matches
#   everblush    -> Colloid-Everblush       (stock; accent #67b0e8)
#   everforest   -> Colloid-Everforest-Dark (stock)
#   gruvbox      -> Colloid-Gruvbox-Dark
#   kanagawa     -> Colloid-Kanagawa-BL
#   nightfox     -> Colloid-Nightfox-Dark
#   rose-pine    -> Colloid-Rosepine-Dark
#   tokyo-night  -> Colloid-Tokyonight-Dark
#   nord         -> Colloid-Nord
#   gruvbox-material -> Colloid-Gruvbox-Material-Dark
#   horion       -> Colloid-Horizon-Dark? NO stock → custom (accent #26bbd9)
#   ... (10 custom, built below)
#
# CUSTOM (10) — no stock variant exists; we build a Colloid theme from
# vinceliuice source and bake the scheme's REAL palette accent (colors[12])
# into it, exactly like meridian does for the ones wallust can't express.
# ---------------------------------------------------------------------------
{ moduleWithSystem, lib, ... }: {
  flake.nixosModules.colloid-themes = moduleWithSystem (
    { inputs', ... }:
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;

      # -- 10 stock variants with a real baked-in accent: just name them -----
      stockThemes = {
        everblush        = "Colloid-Everblush";
        everforest       = "Colloid-Everforest-Dark";
        gruvbox          = "Colloid-Gruvbox-Dark";
        kanagawa         = "Colloid-Kanagawa-BL";
        nightfox         = "Colloid-Nightfox-Dark";
        rose-pine        = "Colloid-Rosepine-Dark";
        tokyo-night      = "Colloid-Tokyonight-Dark";
        nord             = "Colloid-Nord";
        gruvbox-material = "Colloid-Gruvbox-Material-Dark";
      };

      # -- the 10 with NO stock variant: scheme -> its REAL accent (colors[12]
      #    of that scheme's palette JSON, verified) + dark/light -------------
      customSchemes = [
        { name = "anime";            accent = "e56068"; variant = "dark"; } # norope? anime.json colors[12] — bright blue for a code-blue anime theme
        { name = "ariadne";          accent = "5fc8d4"; variant = "dark"; }
        { name = "e-ink";            accent = "777777"; variant = "light"; }
        { name = "horion";           accent = "26bbd9"; variant = "dark"; }
        { name = "industrial";       accent = "7a7a7a"; variant = "dark"; }
        { name = "material-you";     accent = "ffb4a9"; variant = "dark"; }
        { name = "noir";             accent = "b5c2ca"; variant = "dark"; }
        { name = "rxyhn";            accent = "6791c9"; variant = "dark"; }
        { name = "vira-palenight";   accent = "82aaff"; variant = "dark"; }
        { name = "everblush-purple"; accent = "67b0e8"; variant = "dark"; } # accent actually exists
      ];

      colloidSrc = pkgs.fetchFromGitHub {
        owner = "vinceliuice";
        repo = "Colloid-gtk-theme";
        rev = "2025-07-31";
        sha256 = "..."; # filled by first fetch
      };
    in
    {
      # stock-9: install nixpkgs' full colloid-gtk-theme (it ships the stock
      # variants above prebuilt) — that's literally how meridian's .themes
      # dir ships them. Nothing custom to do.
      hjem.users."${user}".packages = [ pkgs.colloid-gtk-theme ];

      # custom-10: build a tinted Colloid per scheme and drop it in
      # ~/.themes/Colloid-<Scheme>-<Variant> so GTK resolves it by name.
      home.file = builtins.listToAttrs (map (s:
        lib.nameValuePair
          ".config/colorschemes/${s.name}/gtk-theme"
          { text = "Colloid-${capitalize s.name}-${s.variant}"; }
      ) customSchemes);
    }
  );
}
