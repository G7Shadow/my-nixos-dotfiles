{ config, ... }:
{
  flake.nixosModules.quickshell =
    { pkgs, inputs, ... }:
    let
      user = config.preferences.user.name;
    in
    {
      hjem.users."${user}".packages = [
        (inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default.withModules [
          pkgs.qt6.qtsvg
          pkgs.qt6.qtimageformats
          pkgs.qt6.qtmultimedia
          pkgs.qt6.qt5compat
        ])
      ];
    };
}
