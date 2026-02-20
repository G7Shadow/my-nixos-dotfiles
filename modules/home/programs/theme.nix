{
  flake.homeModules.theme = {pkgs, ...}: {
    gtk = {
      enable = true;

      cursorTheme = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 24;
      };

      font = {
        name = "Noto Sans";
        size = 11;
      };
    };

    qt = {
      enable = true;
      platformTheme.name = "qt5ct";
    };

    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = ["JetBrainsMono Nerd Font Mono"];
        sansSerif = ["Noto Sans"];
        serif = ["Noto Serif"];
        emoji = ["Noto Color Emoji"];
      };
    };

    xdg.configFile."gtk-3.0/gtk.css".text = ''
      @import 'colors.css';
    '';

    xdg.configFile."gtk-4.0/gtk.css".text = ''
      @import 'colors.css';
    '';

    xdg.configFile."qt5ct/qt5ct.conf".text = ''
      [Appearance]
      color_scheme_path=/home/jeremyl/.config/qt5ct/colors/matugen.conf
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

    xdg.configFile."qt6ct/qt6ct.conf".text = ''
      [Appearance]
      color_scheme_path=/home/jeremyl/.config/qt6ct/colors/matugen.conf
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

    home.pointerCursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
  };
}
