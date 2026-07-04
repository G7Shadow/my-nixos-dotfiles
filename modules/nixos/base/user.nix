{ self, lib, ... }: let
  featuresDir = ../features;
  featureFiles = builtins.attrNames (builtins.readDir featuresDir);
  isNix = f: lib.hasSuffix ".nix" f;
  featureImports = map (f: featuresDir + "/${f}") (builtins.filter isNix featureFiles);
in {
  flake.nixosModules.base = { lib, ... }: {
    imports = [
      self.nixosModules.base_persistance
    ] ++ featureImports;

    options.preferences = {
      user.name = lib.mkOption {
        type = lib.types.str;
        default = "jeremyl";
      };
    };
  };
}
