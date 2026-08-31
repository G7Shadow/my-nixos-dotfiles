{ moduleWithSystem, self, ... }: {
  flake.nixosModules.desktop = moduleWithSystem (
    { ... }:
    { ... }: {
      imports = [
        self.nixosModules.hyprland
        self.nixosModules.kitty
        self.nixosModules.theming
        self.nixosModules.spicetify
        self.nixosModules.virtualization
        self.nixosModules.desktop-packages
        self.nixosModules.dotfiles
        self.nixosModules.neovim
        self.nixosModules.vscodium
      ];
    }
  );
}
