{ ... }: {
  flake.nixosModules.lact = { pkgs, lib, ... }: {
    hardware.amdgpu.overdrive.enable = true;

    services.lact.enable = true;

    systemd.services.lact-monitor = {
      enable = true;
      description = "Set LACT profile on boot based on power source";
      after = [ "lactd.service" ];
      wants = [ "lactd.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe (
          pkgs.writeShellApplication {
            name = "lact-set-profile";
            runtimeInputs = [ pkgs.lact ];
            text = ''
              if grep -q "Battery" /sys/class/power_supply/*/type 2>/dev/null; then
                lact cli profile set "power-saver"
              else
                lact cli profile set "default"
              fi
            '';
          }
        );
        User = "root";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
