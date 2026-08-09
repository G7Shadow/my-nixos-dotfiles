{ moduleWithSystem, ... }: {
  flake.nixosModules.powersave = moduleWithSystem (
    { ... }:
    { pkgs, lib, config, ... }:
    let
      cfg = config.powersave;
    in
    {
      options.powersave = {
        # AMD APU stutter fix: the default BOOTUP_DEFAULT power profile only ramps
        # GPU clocks past a 70% busy threshold, so typical desktop load (10-40%)
        # never boosts — causing intermittent lag. 3D_FULL_SCREEN uses RLC busy
        # signal (USE_RLC_BUSY=1) for responsive clock ramping.
        amdgpuPerf.enable = lib.mkEnableOption "amdgpu 3D_FULL_SCREEN power profile";
      };

      config = lib.mkMerge [
        {
          services.thermald.enable = true;
          powerManagement.powertop.enable = true;

          services.logind.settings.Login = {
            HandleLidSwitch              = "suspend";   # battery
            HandleLidSwitchExternalPower = "lock";      # AC — Quickshell locks
            HandleLidSwitchDocked        = "ignore";    # external monitor
          };

          services.power-profiles-daemon.enable = false;

          services.auto-cpufreq = {
            enable = true;
            settings = {
              charger = {
                governor = "performance";
                turbo = "auto";
              };
              battery = {
                governor = "powersave";
                turbo = "auto";
              };
            };
          };
        }
        (lib.mkIf cfg.amdgpuPerf.enable {
          systemd.services.amdgpu-perf = {
            description = "Set AMD GPU power profile to 3D_FULL_SCREEN";
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = [
                "${pkgs.bash}/bin/bash -c 'for c in /sys/class/drm/card*/device; do if [ -f \"$c/pp_power_profile_mode\" ]; then echo 3D_FULL_SCREEN > \"$c/pp_power_profile_mode\" 2>/dev/null || true; fi; done'"
              ];
            };
          };
        })
      ];
    }
  );
}
