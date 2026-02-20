{...}: {
  flake.nixosModules.hyprland = {pkgs, ...}: {
    # Enable Hyprland
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Enable polkit and dbus for desktop functionality
    security.polkit.enable = true;
    services.dbus.enable = true;

    # XDG portal configuration
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
    };
  };
}
