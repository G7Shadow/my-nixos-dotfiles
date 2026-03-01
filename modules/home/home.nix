{self, ...}: {
  flake.homeModules.base = {
    home.stateVersion = "25.05";
    programs.home-manager.enable = true;
  };

  flake.homeModules.profile-desktop = {
    imports = with self.homeModules; [
      base
      desktop-packages
      dotfiles
      git
      caelestia
      neovim
      theme
      vscodium
      zsh
    ];
  };
}
