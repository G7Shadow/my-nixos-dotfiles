{ moduleWithSystem, ... }: {
  flake.nixosModules.hyprland = moduleWithSystem (
    { self', ... }:
    { config, ... }:
    let
      user = config.preferences.user.name;
    in
    {
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
        withUWSM = true;
      };

      hjem.users."${user}".packages = [ self'.packages.hyprglass ];

      security.polkit.enable = true;
      services.dbus.enable = true;

      persistance.cache.directories = [
        ".local/share/hyprland"
      ];
    }
  );
}
