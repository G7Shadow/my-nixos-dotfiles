{ lib, pkgs, config, ... }:
let
  cfg = config.features.hyprland;
in
{
  options.features.hyprland.enable = lib.mkEnableOption "Hyprland compositor";

  config = lib.mkIf cfg.enable {
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
