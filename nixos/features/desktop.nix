{ moduleWithSystem, self, ... }: {
  flake.nixosModules.desktop = moduleWithSystem (
    { ... }:
    { config, lib, pkgs, ... }: {
      imports = [
        self.nixosModules.hyprland
        self.nixosModules.kitty
        self.nixosModules.theming
        self.nixosModules.virtualization
        self.nixosModules.desktop-packages
        self.nixosModules.dotfiles
        self.nixosModules.neovim
        self.nixosModules.fingerprint
      ];

      environment.systemPackages = lib.optionals config.services.desktopManager.plasma6.enable [
        (pkgs.writeTextDir "share/wayland-sessions/plasma-uwsm.desktop" ''
          [Desktop Entry]
          Name=Plasma (Wayland)
          Comment=Plasma 6 Wayland session
          Exec=${pkgs.kdePackages.plasma-workspace}/libexec/plasma-dbus-run-session-if-needed ${pkgs.kdePackages.plasma-workspace}/bin/startplasma-wayland
          TryExec=${pkgs.kdePackages.plasma-workspace}/bin/startplasma-wayland
          Type=Application
          DesktopNames=KDE
        '')
      ];
    }
  );
}
