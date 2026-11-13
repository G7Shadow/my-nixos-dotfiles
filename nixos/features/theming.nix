{ moduleWithSystem, ... }: {
  flake.nixosModules.theming = moduleWithSystem (
    { inputs', ... }:
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
      awww = inputs'.awww.packages.awww;
    in
    {
      programs.dconf.enable = true;

      # Puts org.gnome.desktop.interface (gtk-theme, color-scheme, fonts, cursors)
      # on the GSettings search path so GTK3 apps can read the theme name from
      # dconf/GSettings (xsettingsd only reaches X11/XWayland apps).
      environment.systemPackages = [ pkgs.gsettings-desktop-schemas ];

      environment.variables = {
        XCURSOR_THEME = "macOS";
        XCURSOR_SIZE = "24";
        HYPRCURSOR_THEME = "macOS";
        HYPRCURSOR_SIZE = "24";
      };

      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        material-symbols
        rubik
        inputs'.apple-fonts.packages.sf-pro
        inputs'.apple-fonts.packages.sf-pro-nerd
        inputs'.apple-fonts.packages.sf-compact
        inputs'.apple-fonts.packages.sf-compact-nerd
        inputs'.apple-fonts.packages.sf-mono
        inputs'.apple-fonts.packages.sf-mono-nerd
        noto-fonts-cjk-sans
      ];

      hjem.users."${user}" = {
        packages = with pkgs; [
          matugen
          wallust
          apple-cursor
          bibata-cursors
          adwaita-icon-theme
          (papirus-icon-theme.override { color = "black"; })
          glib
          nwg-look
          xsettingsd
          adw-gtk3
          libsForQt5.qt5ct
          kdePackages.qt6ct
          cava
          waybar
          hyprpaper
          hypridle
          wlogout
          waypaper
          rofi
          awww
          swaynotificationcenter
          wl-clipboard
          mangohud
          hyprsunset
          nitch
          fastfetch
        ];

        xdg.config.files = {
          "gtk-3.0/settings.ini".text = ''
            [Settings]
            gtk-icon-theme-name=Papirus-Dark
            gtk-cursor-theme-name=macOS
            gtk-cursor-theme-size=24
            gtk-application-prefer-dark-theme=1
          '';
          "gtk-4.0/settings.ini".text = ''
            [Settings]
            gtk-icon-theme-name=Papirus-Dark
            gtk-cursor-theme-name=macOS
            gtk-cursor-theme-size=24
            gtk-application-prefer-dark-theme=1
          '';
          "gtk-3.0/gtk.css".text = "@import 'colors.css';\n@import 'scheme.css';";
          # GTK4/libadwaita only applies this user stylesheet, so import the base
          # Colloid theme + the same per-scheme accent overlay GTK3 uses.
          "gtk-4.0/gtk.css".text = "@import 'theme.css';\n@import 'scheme.css';";
          "gtk-4.0/gtk-dark.css".text = "@import 'theme-dark.css';\n@import 'scheme.css';";

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
  );
}
