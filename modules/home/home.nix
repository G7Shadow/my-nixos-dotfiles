# modules/home/home.nix
{ self, ... }:
{
  flake.nixosModules.profile-desktop = {
    imports = with self.nixosModules; [
      desktop-packages
      dotfiles
      git
      neovim
      quickshell
      theme
      vscodium
      zsh
    ];
  };
}
