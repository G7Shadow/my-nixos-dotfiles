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
      self.nixosModules.extra_hjem
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

      inputs.disko.nixosModules.disko
      self.diskoConfigurations.diskoOmega
    ];

    boot = {
      loader.systemd-boot.enable = true;
      loader.systemd-boot.configurationLimit = 5;
      loader.timeout = 60;
      loader.efi.canTouchEfiVariables = true;
      supportedFilesystems = [ "ntfs" ];
    };

    services.logind.settings.Login = {
      HandleLidSwitch = "poweroff";
      HandleLidSwitchExternalPower = "lock";
      HandleLidSwitchDocked = "ignore";
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
      hostName = "Omega";
      networkmanager.enable = true;
    };

    time.timeZone = "America/Jamaica";
    i18n.defaultLocale = "en_US.UTF-8";

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    security.sudo.enable = false;
    security.doas = {
      enable = true;
      extraRules = [
        {
          users = [ config.preferences.user.name ];
          keepEnv = true;
          persist = true;
        }
      ];
    };

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

    zramSwap = {
      enable = true;
      algorithm = "zstd";
    };

    programs.steam = {
      enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    programs.gamemode.enable = true;

    nix.settings = {
      substituters = [
        "https://hyprland.cachix.org"
      ];
      trusted-substituters = [
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };

    system.stateVersion = "25.05";
  };
}
