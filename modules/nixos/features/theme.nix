{ config, ... }:
{
  flake.nixosModules.theme =
    { pkgs, ... }:
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
            [Appearance]
            color_scheme_path=/home/${user}/.config/qt5ct/colors/matugen.conf
            custom_palette=true
            style=Fusion

            [Interface]
            cursor_flash_time=1000
            double_click_interval=400
            keyboard_scheme=2
            menus_have_icons=true
            show_shortcuts_in_context_menus=true
            stylesheets=@Invalid()
            toolbutton_style=4
            underline_shortcut=1
            wheel_scroll_lines=3
          '';

          "qt6ct/qt6ct.conf".text = ''
            [Appearance]
            color_scheme_path=/home/${user}/.config/qt6ct/colors/matugen.conf
            custom_palette=true
            style=Fusion

            [Interface]
            cursor_flash_time=1000
            double_click_interval=400
            keyboard_scheme=2
            menus_have_icons=true
            show_shortcuts_in_context_menus=true
            stylesheets=@Invalid()
            toolbutton_style=4
            underline_shortcut=1
            wheel_scroll_lines=3
          '';
        };
      };
    };
}
