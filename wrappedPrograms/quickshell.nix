{ inputs, ... }: {
  perSystem = { pkgs, ... }: {
    packages.quickshellWrapped = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.quickshell;
      runtimeInputs = with pkgs; [
        zoxide
        libqalculate
        cliphist
        wl-clipboard
        imagemagick
        brightnessctl
        ddcutil
        playerctl
        hyprsunset
        wallust
        pulseaudio
        grim
        glib
        systemd
      ];
    };
  };
}
