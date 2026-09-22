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

      extensionsEnv = pkgs.buildEnv {
        name = "codium-extensions";
        paths = extensions;
      };

      codium = pkgs.writeShellScriptBin "codium" ''
        store="${extensionsEnv}/share/vscode/extensions"
        export PATH="${pkgs.lib.makeBinPath [ pkgs.trash-cli ]}:$PATH"
        export ELECTRON_TRASH=trash-cli
        dir="$HOME/.vscode-oss/extensions"
        mkdir -p "$dir"
        for ext in "$store"/*; do
          [ -e "$ext" ] || continue
          ln -sfn "$ext" "$dir/$(basename "$ext")"
        done
        exec ${pkgs.vscodium}/bin/codium "$@"
      '';
    in
    {
      hjem.users."${user}".packages = [
        codium
        pkgs.trash-cli
      ];
    }
  );
}