# modules/home/programs/quickshell.nix
{ self, ... }:
{
  flake.nixosModules.quickshell =
    { pkgs, inputs, ... }:
    {
      hjem.users.jeremyl.packages = [
        (inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default.withModules [
          pkgs.qt6.qtsvg
          pkgs.qt6.qtimageformats
          pkgs.qt6.qtmultimedia
          pkgs.qt6.qt5compat
        ])
      ];
    };
}
