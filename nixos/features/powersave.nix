{ moduleWithSystem, ... }: {
  flake.nixosModules.powersave = moduleWithSystem (
    { ... }:
    { ... }: {

      services.thermald.enable = true;
      powerManagement.powertop.enable = true;

      services.logind.settings.Login = {
        HandleLidSwitch = "suspend"; # battery
        HandleLidSwitchExternalPower = "lock"; # AC — Quickshell locks
        HandleLidSwitchDocked = "ignore"; # external monitor
      };

      services.power-profiles-daemon.enable = false;

      services.auto-cpufreq = {
        enable = true;
        settings = {
          charger = {
            governor = "performance";
            turbo = "always";
          };
          battery = {
            governor = "schedutil";
            turbo = "never";
          };
        };
      };
    }
  );
}
