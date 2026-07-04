{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.Omega = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.hostOmega ];
  };

  flake.nixosModules.hostOmega = { config, pkgs, ... }: {
    imports = [
      self.nixosModules.base
      self.nixosModules.impermanence
      self.nixosModules.general
      self.nixosModules.hostOmega-hardware
      self.nixosModules.audio
      self.nixosModules.hyprland
      self.nixosModules.auto-cpufreq
      self.nixosModules.powersave
      self.nixosModules.virtualization
      self.nixosModules.drivers-intel
      self.nixosModules.desktop-packages
      self.nixosModules.dotfiles
      self.nixosModules.kitty
      self.nixosModules.neovim
      self.nixosModules.quickshell
      self.nixosModules.theme
      self.nixosModules.vscodium
      self.nixosModules.gaming

      inputs.disko.nixosModules.disko
      self.diskoConfigurations.diskoOmega

      inputs.nix-index-database.nixosModules.nix-index
    ];

    boot = {
      loader.systemd-boot.enable = true;
      loader.systemd-boot.configurationLimit = 5;
      loader.timeout = 60;
      loader.efi.canTouchEfiVariables = true;
      supportedFilesystems = [ "ntfs" ];
    };

    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "/home/${config.preferences.user.name}/my-nixos-dotfiles";
    };

    programs.nix-index-database.comma.enable = true;

    nix = {
      gc = {
        dates = "weekly";
        options = "--delete-older-than 14d";
      };
      optimise.automatic = true;
      settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

    networking = {
      hostName = "Omega";
      networkmanager.enable = true;
    };

    time.timeZone = "America/Jamaica";
    i18n.defaultLocale = "en_US.UTF-8";

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    security.sudo.enable = true;

    services.displayManager.sddm = {
      enable = true;
      wayland = {
        enable = true;
        compositor = "kwin";
      };
    };

    services.desktopManager.plasma6.enable = true;

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      tree
      git
      direnv
    ];

    services = {
      flatpak.enable = true;
      fwupd.enable = true;
      fstrim.enable = true;
      udisks2.enable = true;
      dbus.enable = true;
    };

    users.users."jeremyl".initialPassword = "changeme";

    system.stateVersion = "25.05";
  };
}
