{ self, ... }:
{
  flake.homeModules.quickshell =
    { pkgs, inputs, ... }:
    {
      home.packages = [
        (inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default.withModules [
          pkgs.qt6.qtsvg
          pkgs.qt6.qtimageformats
          pkgs.qt6.qtmultimedia
          pkgs.qt6.qt5compat
        ])
      ];
    };
}
