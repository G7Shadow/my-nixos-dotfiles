{
  flake.homeModules.theme = {pkgs, ...}: {
    gtk.enable = true;
    qt = {
      enable = true;
      platformTheme.name = "qt5ct";
    };
  };
}
