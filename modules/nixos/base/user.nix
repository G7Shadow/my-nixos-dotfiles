{ self, ... }: {
  flake.nixosModules.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        self.nixosModules.base_persistance
      ];

      options.preferences = {
        user.name = lib.mkOption {
          type = lib.types.str;
          default = "jeremyl";
        };
      };

      config = {
        users.users."${config.preferences.user.name}" = {
          isNormalUser = true;
          group = "${config.preferences.user.name}";
          extraGroups = [ "wheel" ];
          shell = self.packages.${pkgs.stdenv.hostPlatform.system}.environment;
        };
        users.groups."${config.preferences.user.name}" = { };
        environment.systemPackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.environment ];
      };
    };
}
