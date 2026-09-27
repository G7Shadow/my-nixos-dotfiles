{ moduleWithSystem, ... }:
{
  flake.nixosModules.desktop-apps = moduleWithSystem (
    { inputs', ... }:
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
      thunarWithPlugins = pkgs.thunar.override {
        thunarPlugins = [
          pkgs.thunar-archive-plugin
          pkgs.thunar-media-tags-plugin
        ];
      };
    in
    {
      services.gvfs.enable = true;

      services.dbus.packages = [
        thunarWithPlugins
        pkgs.tumbler
      ];

      hjem.users."${user}" = {
        packages = with pkgs; [
          brave
          (vesktop.override { withSystemVencord = true; })
          spotify
          vscodium
          obsidian
          netflix
          localsend
          prismlauncher
          zed-editor
          obs-studio
          thunarWithPlugins
          pkgs.thunar-volman
          pkgs.tumbler
          nautilus
          file-roller
          virt-manager
        ];

        systemd.services = {
          tumbler = {
            description = "Xfce thumbnailer service for Thunar and GTK file choosers";
            startLimitBurst = 5;
            startLimitIntervalSec = 10;
            serviceConfig = {
              Type = "dbus";
              BusName = "org.freedesktop.thumbnails.Thumbnailer1";
              ExecStart = "${pkgs.tumbler}/lib/tumbler-1/tumblerd";
            };
            wantedBy = [ "graphical-session.target" ];
          };

          thunar-volman = {
            description = "Thunar removable drives manager";
            startLimitBurst = 5;
            startLimitIntervalSec = 10;
            serviceConfig.ExecStart = "${pkgs.thunar-volman}/bin/thunar-volman";
            wantedBy = [ "graphical-session.target" ];
          };
        };
      };
    }
  );
}
