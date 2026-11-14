{ moduleWithSystem, ... }: {
  flake.nixosModules.hyprland = moduleWithSystem (
    { self', ... }:
    { ... }:
    {
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
        withUWSM = true;
      };

      # Username-independent path for the plugin loaded in
      # nixos/features/config/hypr/modules/hyprglass.lua.
      environment.etc."hypr/hyprglass.so".source = "${self'.packages.hyprglass}/lib/hyprglass.so";

      security.polkit.enable = true;
      services.dbus.enable = true;

      persistance.cache.directories = [
        ".local/share/hyprland"
      ];
    }
  );
}
