{ ... }: {
  flake.nixosModules.auto-cpufreq = { ... }: {
    services.auto-cpufreq = {
      enable   = true;
      settings = {
        battery = {
          governor = "schedutil";
          turbo    = "never";
        };
        charger = {
          governor = "performance";
          turbo    = "auto";
        };
      };
    };

    # Disable the competing power daemon
    services.power-profiles-daemon.enable = false;
  };
}
