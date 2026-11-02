{ moduleWithSystem, self, ... }: {
  flake.nixosModules.desktop = moduleWithSystem (
    { ... }:
    { config, pkgs, ... }: {
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

      hjem.users."${config.preferences.user.name}".files.".xinitrc" = {
        text = ''
          #!/bin/sh
          exec ${pkgs.kdePackages.plasma-workspace}/bin/startplasma-x11
        '';
        executable = true;
      };
    }
  );
}
