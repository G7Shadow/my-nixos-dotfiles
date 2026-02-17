{
  inputs,
  config,
  ...
}: {
  # Define reusable base module
  flake.homeModules.base = {
    home.stateVersion = "25.05";
    programs.home-manager.enable = true;
  };

  # Automatically collect all homeModules defined in programs/
  flake.homeModules.programs = {
    imports = builtins.attrValues (
      builtins.removeAttrs config.flake.homeModules ["base" "programs"]
    );
  };

  # Define the actual home configuration for standalone use
  flake.homeConfigurations."jeremyl@Omega" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

    extraSpecialArgs = {inherit inputs;};

    modules = [
      inputs.self.homeModules.base
      inputs.self.homeModules.programs
      {
        home = {
          username = "jeremyl";
          homeDirectory = "/home/jeremyl";
        };

        home.packages = with inputs.nixpkgs.legacyPackages.x86_64-linux; [
          # Add your packages here
        ];
      }
    ];
  };
}
