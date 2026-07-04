{ pkgs, config, inputs, ... }:
let
  user = config.preferences.user.name;
in
{
  programs.dconf.enable = true;

  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "Bibata-Modern-Classic";
    HYPRCURSOR_SIZE = "24";
  };

  hjem.users."${user}" = {
    packages = with pkgs; [
      matugen
      wallust
      bibata-cursors
      nerd-fonts.jetbrains-mono
      rubik
      noto-fonts-cjk-sans
      adwaita-icon-theme
      (papirus-icon-theme.override { color = "black"; })
      glib
      adwsteamgtk
      nwg-look
      xsettingsd
      adw-gtk3
      libsForQt5.qt5ct
      kdePackages.qt6ct
      pywalfox-native
      cava
      waybar
      hyprpaper
      hyprlock
      hypridle
      wlogout
      waypaper
      rofi
      inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.awww
      swaynotificationcenter
      wl-clipboard
      mangohud
      hyprsunset
      nitch
      fastfetch
    ];

    xdg.config.files = {
      "gtk-3.0/gtk.css".text = "@import 'colors.css'";
      "gtk-4.0/gtk.css".text = "@import 'colors.css'";

      "qt5ct/qt5ct.conf".text = ''
        color_scheme_path=~/.local/share/color-schemes/Matugen.colors
        custom_palette=true
        icon_theme=breeze
        style=<Breeze>
      '';

      "qt6ct/qt6ct.conf".text = ''
        color_scheme_path=~/.local/share/color-schemes/Matugen.colors
        custom_palette=true
        icon_theme=breeze
        style=<Breeze>
      '';
    };
  };
}
