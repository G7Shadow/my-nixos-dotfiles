{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.Omega = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {inherit inputs self;};

    modules = [
      self.nixosModules.hostOmega
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
    imports = [
      self.nixosModules.system
      inputs.home-manager.nixosModules.home-manager
    ];

    boot = {
      loader.systemd-boot.enable = true;
      loader.systemd-boot.configurationLimit = 5;
      loader.timeout = 60;
      loader.efi.canTouchEfiVariables = true;
      kernelParams = ["amdgpu.ppfeaturemask=0xffffffff"];
    };

    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "/home/jeremyl/my-nixos-dotfiles";
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

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    services.flatpak.enable = true;

    services = {
      fwupd.enable = true;
      fstrim.enable = true;
      dbus.enable = true;
    };

    programs.steam = {
      enable = true;
      extraCompatPackages = [pkgs.proton-ge-bin];
    };

    programs.gamemode.enable = true;

    nix.settings.experimental-features = ["nix-command" "flakes"];

    system.stateVersion = "25.05";
  };
}
