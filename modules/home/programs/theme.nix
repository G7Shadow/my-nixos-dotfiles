{
  flake.homeModules.theme = {pkgs, ...}: {
    gtk.enable = true;
    qt.enable = true;
  };
}
