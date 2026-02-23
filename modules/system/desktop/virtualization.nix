{ ... }: {
  flake.nixosModules.virtualization = { pkgs, ... }: {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package    = pkgs.qemu_kvm;
        runAsRoot  = true;
        swtpm.enable = true;
      };
    };

    programs.virt-manager.enable   = true;
    programs.dconf.enable          = true;

    users.users.jeremyl.extraGroups = [ "libvirtd" ];

    virtualisation.spiceUSBRedirection.enable = true;

    environment.systemPackages = with pkgs; [
      spice-gtk
      virglrenderer
      looking-glass-client
    ];
  };
}
