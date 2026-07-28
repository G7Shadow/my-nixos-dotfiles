{ ... }: {
  flake.nixosModules.hyprland = { ... }: {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };

    security.polkit.enable = true;
    services.dbus.enable = true;

    persistance.cache.directories = [
      ".local/share/hyprland"
    ];
  };
}
