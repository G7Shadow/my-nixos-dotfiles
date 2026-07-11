{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.Alpha = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.hostAlpha ];
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

      hardware.bluetooth.enable = true;

      # --- AMD GPU power management (synced to CPU power profile) ---
      hardware.amdgpu.overdrive.enable = true;
      services.lact.enable = true;

      systemd.services.lact-monitor = {
        enable = true;
        description = "Monitor PowerProfiles and update LACT profile";
        after = [
          "network.target"
          "lactd.service"
          "power-profiles-daemon.service"
        ];
        wants = [
          "lactd.service"
          "power-profiles-daemon.service"
        ];
        serviceConfig = {
          Type = "simple";
          ExecStartPre = lib.getExe (
            pkgs.writeShellApplication {
              name = "lact-initial-set";
              runtimeInputs = [
                pkgs.lact
                pkgs.glib
                pkgs.dbus
                pkgs.power-profiles-daemon
              ];
              text = ''
                profile=$(powerprofilesctl get)
                if [[ $profile == "power-saver" ]]; then
                    lact cli profile set "power-saver"
                else
                    lact cli profile set "default"
                fi
              '';
            }
          );
          ExecStart = lib.getExe (
            pkgs.writeShellApplication {
              name = "lact-watcher";
              runtimeInputs = [
                pkgs.libnotify
                pkgs.lact
                pkgs.glib
                pkgs.dbus
              ];
              text = ''
                gdbus monitor --system --dest net.hadess.PowerProfiles |
                while read -r line; do
                    if [[ $line =~ ActiveProfile ]]; then
                        profile=$(echo "$line" | grep -oP "(?<=<').+?(?='>)")

                        if [[ $profile == "power-saver" ]]; then
                            lact cli profile set "power-saver"
                        else
                            lact cli profile set "default"
                        fi
                    fi
                done
              '';
            }
          );
          Restart = "always";
          User = "root";
        };
        wantedBy = [ "multi-user.target" ];
      };

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
