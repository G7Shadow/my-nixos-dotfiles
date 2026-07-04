{ self, ... }: {
  flake.nixosModules.base = { lib, ... }: {
    imports = [
      self.nixosModules.base_persistance
    ];

    options.preferences = {
      user.name = lib.mkOption {
        type = lib.types.str;
        default = "jeremyl";
      };
    };
  };
}
