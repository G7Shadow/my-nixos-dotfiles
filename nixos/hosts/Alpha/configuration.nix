{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.Alpha = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.hostAlpha
    ];
  };

  flake.nixosModules.hostAlpha =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        self.nixosModules.base

        self.nixosModules.general
        self.nixosModules.desktop
        self.nixosModules.quickshell
        self.nixosModules.pipewire
        self.nixosModules.powersave
        self.nixosModules.gaming
        self.nixosModules.hostAlpha-hardware
      ];

      boot = {
        kernelPackages = pkgs.linuxPackages_latest;
        loader.systemd-boot.enable = true;
        loader.systemd-boot.configurationLimit = 5;
        loader.timeout = 60;
        loader.efi.canTouchEfiVariables = true;
        supportedFilesystems = [ "ntfs" ];
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

      services.displayManager.sddm = {
        enable = true;
        wayland = {
          enable = true;
          compositor = "kwin";
        };
      };

      services.desktopManager.plasma6.enable = true;

      hardware.cpu.amd.updateMicrocode = true;
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          rocmPackages.clr.icd
        ];
      };

      hardware.amdgpu.overdrive.enable = true;


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
