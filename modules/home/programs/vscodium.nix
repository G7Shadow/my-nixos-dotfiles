{ self, ... }: {
  flake.homeModules.vscodium = { pkgs, inputs, ... }: {
    programs.vscode = {
      enable    = true;
      package   = pkgs.vscodium;
      mutableExtensionsDir = true;

      profiles.default = {
        extensions = let
          marketplace = inputs.nix-vscode-extensions.extensions.${pkgs.stdenv.hostPlatform.system}.vscode-marketplace;
        in [
          marketplace.jnoortheen.nix-ide
          marketplace.mkhl.direnv
          marketplace.kamadorueda.alejandra
          marketplace.enkia.tokyo-night
          marketplace.pkief.material-product-icons
          marketplace.pkief.material-icon-theme
          marketplace.asvetliakov.vscode-neovim
        ];
      };
    };
  };
}
