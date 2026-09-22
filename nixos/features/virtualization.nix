{ moduleWithSystem, ... }: {
  flake.nixosModules.virtualization = moduleWithSystem (
    { ... }:
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
    in
    {
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
          swtpm.enable = true;
        };
      };

      programs.virt-manager.enable = true;
      programs.dconf.enable = true;

      users.users."${user}".extraGroups = [ "libvirtd" ];

      networking.firewall.trustedInterfaces = [ "virbr0" ];

      systemd.services.libvirt-default-network = {
        description = "Start libvirt default network";
        after = [ "libvirtd.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.libvirt}/bin/virsh net-start default";
          ExecStop = "${pkgs.libvirt}/bin/virsh net-destroy default";
        };
      };

      virtualisation.spiceUSBRedirection.enable = true;
      services.spice-vdagentd.enable = true;
      services.qemuGuest.enable = true;

      environment.systemPackages = with pkgs; [
        OVMF
        spice-gtk
        virglrenderer
        looking-glass-client
      ];
    }
  );
}
