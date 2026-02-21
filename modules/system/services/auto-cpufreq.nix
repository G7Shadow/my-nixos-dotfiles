{...}: {
  flake.nixosModules.auto-cpufreq = {
    pkgs,
    config,
    ...
  }: {
    services.auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "schedutil";
          turbo = "auto";
        };
      };
    };

    services.power-profiles-daemon.enable = false;
  };
}
