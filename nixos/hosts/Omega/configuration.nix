{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.Omega = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.hostOmega
    ];
  };

  flake.nixosModules.hostOmega = { config, pkgs, ... }: {
    imports = [
      self.nixosModules.base

      self.nixosModules.general
      self.nixosModules.desktop
      self.nixosModules.pipewire
      self.nixosModules.gaming
      self.nixosModules.quickshell
      self.nixosModules.powersave
      self.nixosModules.hostOmega-hardware
      self.nixosModules.impermanence

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

    networking = {
      hostName = "Omega";
      networkmanager.enable = true;
    };

    time.timeZone = "America/Jamaica";
    i18n.defaultLocale = "en_US.UTF-8";

    hardware.cpu.intel.updateMicrocode = true;
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
      ];
    };

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    services.displayManager.sddm = {
      enable = true;
      wayland = {
        enable = true;
        compositor = "kwin";
      };
    };

    services.desktopManager.plasma6.enable = true;

    services = {
      flatpak.enable = true;
      fwupd.enable = true;
      fstrim.enable = true;
      udisks2.enable = true;
      dbus.enable = true;
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    nix.optimise.automatic = true;

    system.stateVersion = "25.05";
  };
}
