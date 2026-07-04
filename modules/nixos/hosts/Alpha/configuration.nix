{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.Alpha = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.hostAlpha ];
  };

  flake.nixosModules.hostAlpha = { config, pkgs, ... }: {
    imports = [
      self.nixosModules.base
      self.nixosModules.extra_hjem
      self.nixosModules.hostAlpha-hardware
      self.nixosModules.profile-laptop
      self.nixosModules.desktop-packages
      self.nixosModules.dotfiles
      self.nixosModules.kitty
      self.nixosModules.neovim
      self.nixosModules.quickshell
      self.nixosModules.theme
      self.nixosModules.vscodium
      self.nixosModules.gaming
    ];

    boot = {
      kernelPackages = pkgs.linuxPackages_latest;
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
      hostName = "Alpha";
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

    hardware.bluetooth.enable = true;

    services = {
      flatpak.enable = true;
      fwupd.enable = true;
      fstrim.enable = true;
      udisks2.enable = true;
      dbus.enable = true;
    };

    zramSwap = {
      enable = true;
      algorithm = "zstd";
    };

    system.stateVersion = "25.05";
  };
}
