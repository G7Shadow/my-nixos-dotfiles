{config, ...}: {
  # Automatically collect all system modules
  flake.nixosModules.settings = {
    imports = builtins.attrValues (
      builtins.removeAttrs config.flake.nixosModules [
        "system"
        "hostOmega"
      ]
    );
  };
}
