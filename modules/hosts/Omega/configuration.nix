{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.Omega = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {inherit inputs self;};

    modules = [
      self.nixosModules.hostOmega
      self.nixosModules.system
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = {inherit inputs self;};

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

  flake.nixosModules.hostOmega = {pkgs, ...}: {
    boot = {
      loader.systemd-boot.enable = true;
      loader.systemd-boot.configurationLimit = 5;
      loader.timeout = 60;
      loader.efi.canTouchEfiVariables = true;
    };

    nix.gc = {
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    nix.optimise.automatic = true;

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
      extraGroups = ["networkmanager" "wheel"];
      shell = pkgs.zsh;
    };

    programs.zsh.enable = true;

    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      tree
    ];

    # Additional optimizations for Ryzen mobile + Vega
    hardware.cpu.amd.updateMicrocode = true;

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
        libva
        libva-vdpau-driver
      ];
    };

    nix.settings.experimental-features = ["nix-command" "flakes"];

    system.stateVersion = "25.05";
  };
}
