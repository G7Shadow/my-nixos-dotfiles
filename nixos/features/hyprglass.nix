{ inputs, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.hyprglass = pkgs.hyprlandPlugins.mkHyprlandPlugin {
        pluginName = "hyprglass";
        version = "0.7.0";

        src = pkgs.fetchFromGitHub {
          owner = "hyprnux";
          repo = "hyprglass";
          rev = "v0.7.0";
          hash = "sha256-x/584kY+XXlU/OWKtZAFo89VtowjLXs1DiP9PC0o0Os=";
        };

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
