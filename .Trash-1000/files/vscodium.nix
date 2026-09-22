{ moduleWithSystem, ... }:
{
  flake.nixosModules.vscodium = moduleWithSystem (
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;

      codiumScript = pkgs.writeShellScriptBin "codium" ''
        export PATH="${pkgs.lib.makeBinPath [ pkgs.trash-cli ]}:$PATH"
        export ELECTRON_TRASH=trash-cli
        exec ${pkgs.vscodium}/bin/codium "$@"
      '';

      codium =
        pkgs.runCommand "vscodium-wrapped"
          ''
            mkdir -p $out/bin $out/share/applications
            cp ${codiumScript}/bin/codium $out/bin/codium
            chmod +x $out/bin/codium
            cp -r ${pkgs.vscodium}/share/applications/*.desktop $out/share/applications/
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
