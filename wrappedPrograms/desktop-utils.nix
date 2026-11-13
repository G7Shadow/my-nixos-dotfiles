{ ... }:
{
  flake.nixosModules.desktop-utils =
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
    in
    {
      hjem.users."${user}".packages = with pkgs; [
        brightnessctl
        ddcutil
        grim
        lm_sensors
        ffmpeg
        pulsemixer
        pwvucontrol
        imagemagick
        feh
        gvfs
        libnotify
        dunst
        ntfs3g
        playerctl
        protonup-ng
        bluez
        cliphist
        wl-clipboard
        libqalculate
        pulseaudio
      ];
    };
}
