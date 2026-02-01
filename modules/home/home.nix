{ config, ... }:
{
  # Define reusable modules
  flake.homeModules.base = {
    home.stateVersion = "25.05";
    programs.home-manager.enable = true;
  };
  
  # Define the actual home configuration
  flake.homeConfigurations."jeremyl@Omega" = { pkgs, ... }: {
    imports = [
      config.flake.homeModules.base
      ./programs/zsh.nix
    ];
    
    home = {
      username = "jeremyl";
      homeDirectory = "/home/jeremyl";
    };
    
    home.packages = with pkgs; [
      # Add packages here
    ];
  };
}
