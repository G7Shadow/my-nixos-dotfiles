{
  flake.homeModules.theme = {pkgs, ...}: {
    gtk = {
      enable = true;

      cursorTheme = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 24;
      };
    };
    qt = {
      enable = true;
      platformTheme.name = "qt5ct";
    };

    xdg.configFile."gtk-3.0/gtk.css".text = ''
      @import 'colors.css';
    '';

    xdg.configFile."gtk-4.0/gtk.css".text = ''
      @import 'colors.css';
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
