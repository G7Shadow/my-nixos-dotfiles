{ moduleWithSystem, ... }: {
  flake.nixosModules.powersave = moduleWithSystem (
    { ... }:
    { ... }: {
      services.thermald.enable = true;
      powerManagement.powertop.enable = true;

      services.power-profiles-daemon.enable = false;

      services.auto-cpufreq = {
        enable = true;
        settings = {
          charger = {
            governor = "performance";
            turbo = "auto";
          };
          battery = {
            governor = "powersave";
            turbo = "auto";
          };
        };
      };
    }
  );
}
