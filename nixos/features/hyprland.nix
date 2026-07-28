{ inputs, ... }: {
  flake.nixosModules.hyprland = {
    pkgs,
    lib,
    ...
  }: let
    hyprglass = pkgs.stdenv.mkDerivation {
      pname = "hyprglass";
      version = "0.6.4";
      src = inputs.hyprglass;

      nativeBuildInputs = with pkgs; [
        pkg-config
        glslang
      ];

      buildInputs = with pkgs; [
        hyprland.dev
        aquamarine
        wayland
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
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
      package = pkgs.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
      plugins = [ hyprglass ];
      extraConfig = "source = ~/.config/hypr/hyprland.lua";
    };

    security.polkit.enable = true;
    services.dbus.enable = true;

    persistance.cache.directories = [
      ".local/share/hyprland"
    ];
  };
}
