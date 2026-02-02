{...}: {
  flake.nixosModules.auto-cpufreg = {
    pkgs,
    config,
    ...
  }: {
    services.auto-cpufreq = {
      enable = true;
    };
    services.power-profiles-daemon.enable = false;
  };
}
