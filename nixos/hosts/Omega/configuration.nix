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

  flake.nixosModules.hostOmega = { config, pkgs, lib, ... }: {
    imports = [
      self.nixosModules.base

      self.nixosModules.general
      self.nixosModules.desktop
      self.nixosModules.pipewire
      self.nixosModules.gaming
      self.nixosModules.quickshell
      self.nixosModules.powersave
      self.nixosModules.podman
      self.nixosModules.hostOmega-hardware
      self.nixosModules.impermanence

      inputs.disko.nixosModules.disko
      self.diskoConfigurations.diskoOmega
    ];

    boot = {
      loader.systemd-boot.enable = true;
      loader.systemd-boot.configurationLimit = 5;
      loader.timeout = 3;
      loader.efi.canTouchEfiVariables = true;
      supportedFilesystems = [ "ntfs" ];
    };

    zramSwap = {
      enable = true;
      memoryPercent = 50;
    };

    boot.kernel.sysctl = {
      "vm.swappiness" = 100;
      "vm.page-cluster" = 0;
    };

    networking = {
      hostName = "Omega";
      networkmanager.enable = true;
      modemmanager.enable = false;
    };

    hardware.bluetooth.enable = true;

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

    services.desktopManager.plasma6.enable = true;

    services.displayManager = {
      defaultSession = "hyprland-uwsm";
      sddm = {
        enable = true;
      };
    };

    services = {
      xserver.enable = true;
      flatpak.enable = true;
      fwupd.enable = true;
      fstrim.enable = true;
      udisks2.enable = true;
      dbus.enable = true;
      thermald.enable = lib.mkForce false;
      qemuGuest.enable = lib.mkForce false;
      spice-vdagentd.enable = lib.mkForce false;
    };

    powerManagement.powertop.enable = lib.mkForce false;

    systemd.services = {
      NetworkManager-wait-online.enable = false;
      libvirtd.wantedBy = lib.mkForce [ ];
      libvirt-guests.wantedBy = lib.mkForce [ ];
      libvirt-default-network.wantedBy = lib.mkForce [ "libvirtd.service" ];
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
