{
  flake.homeModules.vscodium = {pkgs, inputs, ...}: {
    programs.vscode = {
      enable = true;
      package = pkgs.vscodium;

      extensions = 
        let
          marketplace = inputs.nix-vscode-extensions.extensions.${pkgs.system}.vscode-marketplace;
        in [
          marketplace.jnoortheen.nix-ide
          marketplace.mkhl.direnv
          marketplace.kamadorueda.alejandra
          marketplace.enkia.tokyo-night   # matches your tokyonight neovim theme
        ];
    };
  };
}