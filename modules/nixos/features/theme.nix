{ ... }:
{
  flake.nixosModules.theme =
    { pkgs, config, ... }:
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
          bibata-cursors
          adw-gtk3
          adwaita-icon-theme
          (papirus-icon-theme.override { color = "black"; })
          glib
          libsForQt5.qt5ct
          kdePackages.qt6ct
          nerd-fonts.jetbrains-mono
          rubik
          noto-fonts-cjk-sans
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
    };
}
