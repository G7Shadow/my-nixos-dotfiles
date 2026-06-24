{ config, inputs, ... }:
{
  flake.nixosModules.vscodium =
    { pkgs, ... }:
    let
      user = config.preferences.user.name;
    in
    {
      hjem.users."${user}".packages =
        let
          marketplace =
            inputs.nix-vscode-extensions.extensions.${pkgs.stdenv.hostPlatform.system}.vscode-marketplace;
        in
        [
          pkgs.vscodium
          marketplace.jnoortheen.nix-ide
          marketplace.mkhl.direnv
          marketplace.kamadorueda.alejandra
          marketplace.enkia.tokyo-night
          marketplace.pkief.material-product-icons
          marketplace.pkief.material-icon-theme
          marketplace.asvetliakov.vscode-neovim
          marketplace.theqtcompany.qt-qml
        ];
    };
}
