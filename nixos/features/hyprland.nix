{ ... }: {
  flake.nixosModules.hyprland = { pkgs, ... }: {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      package = pkgs.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };

    security.polkit.enable = true;
    services.dbus.enable = true;

    persistance.cache.directories = [
      ".local/share/hyprland"
    ];
  };
}
