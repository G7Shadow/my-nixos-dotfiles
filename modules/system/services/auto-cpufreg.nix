{...}: {
  flake.nixosModules.auto-cpufreg = {
    pkgs,
    config,
    ...
  }: {
    services.auto-cpufreq = {
      enable = true;
      settings = {
        # Performance mode when on battery
        battery = {
          governor = "balanced";
          turbo = "never";
        };

        # Performance mode when plugged in
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };

    services.power-profiles-daemon.enable = false;
  };
}
