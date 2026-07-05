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
        lm_sensors
        ffmpeg
        pulsemixer
        pwvucontrol
        imagemagick
        feh
        gvfs
        ntfs3g
        playerctl
        protonup-ng
        bluez
      ];
    };
}
