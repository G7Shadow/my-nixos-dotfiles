{ self, ... }: {
  flake.nixosModules.quickshell = { pkgs, config, ... }: {
    hjem.users."${config.preferences.user.name}".packages = [
      self.packages.${pkgs.system}.quickshellWrapped
    ];
  };
}
