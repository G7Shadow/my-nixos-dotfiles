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

      codiumScript = pkgs.writeShellScriptBin "codium" ''
        store="${extensionsEnv}/share/vscode/extensions"
        export PATH="${pkgs.lib.makeBinPath [ pkgs.trash-cli ]}:$PATH"
        export ELECTRON_TRASH=trash-cli
        dir="$HOME/.vscode-oss/extensions"
        mkdir -p "$dir"
        for ext in "$store"/*; do
          [ -e "$ext" ] || continue
          ln -sfn "$ext" "$dir/$(basename "$ext")" 2>/dev/null || true
        done
        exec ${pkgs.vscodium}/bin/codium "$@"
      '';

      codium = pkgs.runCommand "vscodium-wrapped" {
        buildInputs = [ pkgs.imagemagick ];
      } ''
        mkdir -p $out/bin $out/share/applications
        cp ${codiumScript}/bin/codium $out/bin/codium
        chmod +x $out/bin/codium
        cp -r ${pkgs.vscodium}/share/applications/*.desktop $out/share/applications/

        # The upstream package only ships the icon at 1024x1024, which is not a
        # registered size in hicolor's index.theme, so Qt's icon lookup (QIcon::
        # fromTheme — used by the quickshell launcher) never finds it. Bake it
        # into the sizes hicolor actually declares.
        source="${pkgs.vscodium}/share/icons/hicolor/1024x1024/apps/vscodium.png"
        for size in 16 22 24 32 48 64 128 256 512; do
          mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
          convert "$source" -resize ''${size}x''${size} $out/share/icons/hicolor/''${size}x''${size}/apps/vscodium.png
          if [ "$size" -le 256 ]; then
            mkdir -p $out/share/icons/hicolor/''${size}x''${size}@2/apps
            convert "$source" -resize $((size * 2))x$((size * 2)) $out/share/icons/hicolor/''${size}x''${size}@2/apps/vscodium.png
          fi
        done
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