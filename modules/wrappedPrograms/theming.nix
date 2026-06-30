{ inputs, ... }:
{
  flake.nixosModules.theming =
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
    in
    {
      hjem.users."${user}".packages = with pkgs; [
        matugen
        wallust
        bibata-cursors
        nerd-fonts.jetbrains-mono
        rubik
        noto-fonts-cjk-sans
        adwaita-icon-theme
        (papirus-icon-theme.override { color = "black"; })
        adwsteamgtk
        nwg-look
        xsettingsd
        adw-gtk3
        libsForQt5.qt5ct
        kdePackages.qt6ct
        pywalfox-native
        cava
        waybar
        hyprpaper
        hyprlock
        hypridle
        wlogout
        waypaper
        rofi
        inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.awww
        swaynotificationcenter
        wl-clipboard
        mangohud
        hyprsunset
        nitch
        fastfetch
      ];
    };
}
