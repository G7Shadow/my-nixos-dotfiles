{ self, ... }: {
  flake.nixosModules.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
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
          shell = self.packages.${pkgs.system}.environment;
        };
        users.groups."${config.preferences.user.name}" = { };
        environment.systemPackages = [ self.packages.${pkgs.system}.environment ];
      };
    };
}
