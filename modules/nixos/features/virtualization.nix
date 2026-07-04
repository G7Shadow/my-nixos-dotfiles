{ lib, pkgs, config, ... }:
let
  user = config.preferences.user.name;
  cfg = config.features.virtualization;
in
{
  options.features.virtualization.enable = lib.mkEnableOption "Virtualization (libvirt)";

  config = lib.mkIf cfg.enable {
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

    virtualisation.spiceUSBRedirection.enable = true;

    environment.systemPackages = with pkgs; [
      spice-gtk
      virglrenderer
      looking-glass-client
    ];
  };
}
