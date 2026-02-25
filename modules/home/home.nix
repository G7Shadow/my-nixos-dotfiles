{
  inputs,
  self,
  ...
}: {
  # Base module: minimum required for any home-manager user
  flake.homeModules.base = {
    home.stateVersion = "25.05";
    programs.home-manager.enable = true;
  };

  # Desktop profile: all programs a desktop user needs
  # Import this in any user that needs a full desktop environment
  flake.homeModules.profile-desktop = {
    imports = with self.homeModules; [
      base
      desktop-packages
      dotfiles
      git
      neovim
      theme
      spicetify
      vscodium
      zsh
    ];
  };
}
