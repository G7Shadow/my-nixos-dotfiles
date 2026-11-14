{ inputs, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.hyprglass = pkgs.hyprlandPlugins.mkHyprlandPlugin {
        pluginName = "hyprglass";
        version = "1.1.1";

        src = pkgs.fetchFromGitHub {
          owner = "hyprnux";
          repo = "hyprglass";
          rev = "v1.1.1";
          hash = "sha256-cQmVmmdaITss2hO6aidKOtq6GtEe85fmgrPcrn1eIUg=";
        };

        nativeBuildInputs = [ pkgs.wayland-scanner ];
        buildInputs = [ pkgs.pixman ];

        installPhase = ''
          runHook preInstall
          install -Dm755 hyprglass.so $out/lib/hyprglass.so
          runHook postInstall
        '';

        meta = {
          description = "Hyprland plugin that adds Liquid Glass blur, refraction and lens effects to transparent windows";
          homepage = "https://github.com/hyprnux/hyprglass";
          license = pkgs.lib.licenses.bsd3;
          platforms = pkgs.lib.platforms.linux;
        };
      };
    };
}
