{ inputs, ... }: {
  flake.nixosModules.hyprglass = {
    pkgs,
    lib,
    ...
  }: let
    hyprglass = pkgs.hyprlandPlugins.mkHyprlandPlugin {
      pname = "hyprglass";
      version = "0.6.4";
      src = inputs.hyprglass;

      nativeBuildInputs = with pkgs; [
        pkg-config
        glslang
      ];

      buildPhase = ''
        make
      '';

      installPhase = ''
        mkdir -p $out/lib
        cp hyprglass.so $out/lib/libhyprglass.so
      '';

      meta = {
        description = "Apple-style Liquid Glass effect for Hyprland";
        homepage = "https://github.com/hyprnux/hyprglass";
        license = lib.licenses.mit;
        platforms = lib.platforms.linux;
      };
    };
  in {
    environment.systemPackages = [hyprglass];
    environment.etc."hypr/hyprglass.so".source = "${hyprglass}/lib/libhyprglass.so";
  };
}
