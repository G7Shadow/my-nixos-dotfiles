{config, ...}: {
  # Automatically collect all system modules
  flake.nixosModules.system = {
    imports = builtins.attrValues (
      builtins.removeAttrs config.flake.nixosModules [
        "system"
        "hostOmega"
      ]
    );
  };
}
