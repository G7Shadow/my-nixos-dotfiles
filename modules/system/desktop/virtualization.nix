{...}: {
  flake.nixosModules.virtualization = {pkgs, ...}: {
    # Enable virtualization
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;  # TPM support for Windows 11
        # OVMF is now automatically available, no need to configure it
      };
    };

    # Install virt-manager and related tools
    programs.virt-manager.enable = true;

    # Add your user to libvirtd group
    users.users.jeremyl.extraGroups = ["libvirtd"];

    # Enable dconf (required for virt-manager)
    programs.dconf.enable = true;

    # Enable USB redirection support
    virtualisation.spiceUSBRedirection.enable = true;

    # Additional packages for better VM experience
    environment.systemPackages = with pkgs; [
      spice-gtk        # SPICE client for USB redirection
      virglrenderer    # 3D acceleration support
      looking-glass-client  # Optional: for near-native gaming performance
    ];
  };
}
