{ moduleWithSystem, ... }:
{
  flake.nixosModules.vscodium = moduleWithSystem (
    { inputs', ... }:
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
      marketplace = inputs'.nix-vscode-extensions.extensions.vscode-marketplace;
      extensions = [
        marketplace.jnoortheen.nix-ide
        marketplace.mkhl.direnv
        marketplace.kamadorueda.alejandra
        marketplace.enkia.tokyo-night
        marketplace.pkief.material-product-icons
        marketplace.pkief.material-icon-theme
        marketplace.asvetliakov.vscode-neovim
        marketplace.theqtcompany.qt-qml
      ];
    in
    {
      hjem.users."${user}".packages = [
        (pkgs.vscode-with-extensions.override {
          vscode = pkgs.vscodium;
          vscodeExtensions = extensions;
        })
      ];
    }
  );
}