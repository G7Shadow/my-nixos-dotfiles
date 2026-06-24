{ inputs, ... }: {
  imports = [
    inputs.wrapper-modules.flakeModules.wrappers
    inputs.flake-parts.flakeModules.modules
  ];

  options = {
    flake = inputs.flake-parts.lib.mkSubmoduleOptions {
      wrappersModules = inputs.nixpkgs.lib.mkOption {
        default = { };
      };
    };
  };

  config = {
    systems = [
      "x86_64-linux"
    ];
  };
}
