{ inputs, self, ... }: {
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
      vscodium
      zsh
    ];
  };

  # Standalone home-manager configuration (used with `home-manager switch`)
  # Uses the same profile as the NixOS-integrated config
  flake.homeConfigurations."jeremyl@Omega" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    extraSpecialArgs = { inherit inputs self; };
    modules = [
      self.homeModules.profile-desktop
      {
        home = {
          username = "jeremyl";
          homeDirectory = "/home/jeremyl";
        };
      }
    ];
  };
}
