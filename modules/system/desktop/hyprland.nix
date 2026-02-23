{ ... }: {
  flake.nixosModules.hyprland = { pkgs, ... }: {
    programs.hyprland = {
      enable         = true;
      xwayland.enable = true;
    };

    security.polkit.enable = true;
    services.dbus.enable   = true;

    xdg.portal = {
      enable       = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };
}
