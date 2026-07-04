{ lib, config, self, ... }:
{
  imports = [
    self.nixosModules.extra_impermanence
  ];

  options.features.impermanence.enable = lib.mkEnableOption "impermanence (ephemeral root)";

  config = lib.mkIf config.features.impermanence.enable {
    persistance.enable = true;
    persistance.user = config.preferences.user.name;
  };
}
