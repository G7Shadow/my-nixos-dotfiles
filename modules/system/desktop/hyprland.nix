{...}: {
  flake.nixosModules.hyprland = {pkgs, ...}: {
    # Enable Hyprland
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Required for Hyprland
    security.polkit.enable = true;

    # XDG portal configuration
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
    };
  };
}
