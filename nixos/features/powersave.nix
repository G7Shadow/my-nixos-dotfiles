{ ... }: {
  flake.nixosModules.powersave = { ... }: {
    services.thermald.enable = true;
    powerManagement.powertop.enable = true;

    services.auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "schedutil";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };

    services.power-profiles-daemon.enable = false;
  };
}
