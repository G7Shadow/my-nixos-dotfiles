{ ... }: {
  flake.nixosModules.powersave = { ... }: {
    services.thermald.enable = true;
    powerManagement.powertop.enable = true;

    services.power-profiles-daemon.enable = true;
  };
}
