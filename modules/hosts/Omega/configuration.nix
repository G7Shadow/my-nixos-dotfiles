{ inputs, self, ... }: {
  flake.nixosConfigurations.Omega = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs self; };
    
    modules = [
      self.nixosModules.hostOmega
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs self; };
          
          users.jeremyl = {
            imports = [
              self.homeModules.base
              self.homeModules.programs
            ];
            
            home = {
              username = "jeremyl";
              homeDirectory = "/home/jeremyl";
            };
          };
        };
      }
    ];
  };

  flake.nixosModules.hostOmega = { pkgs, ... }: {
    boot = {
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
    };

    networking.hostName = "Omega";
    networking.networkmanager.enable = true;
    time.timeZone = "America/Jamaica";
    i18n.defaultLocale = "en_US.UTF-8";

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    users.users.jeremyl = {
      isNormalUser = true;
      description = "Jeremy Lee";
      extraGroups = [ "networkmanager" "wheel" ];
      shell = pkgs.zsh;
    };

    programs.zsh.enable = true;

    # Fixed: Use new option names
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      neovim
      git
      tree
    ];

    nix.settings.experimental-features = ["nix-command" "flakes"];

    system.stateVersion = "25.05";
  };
}
