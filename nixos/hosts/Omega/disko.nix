{
  flake.diskoConfigurations.diskoOmega = {
    disko.devices = {
      disk.main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-INSERT_YOUR_SSD_ID_HERE";
        content = {
          type = "gpt";
          partitions = {
            boot = { size = "1M"; type = "EF02"; };
            esp = {
              size = "1G"; type = "EF00";
              content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot"; };
            };
            swap = { size = "16G"; content = { type = "swap"; resumeDevice = true; }; };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                passwordFile = "/tmp/secret.key";
                content = {
                  type = "lvm_pv";
                  vg = "btrfs_vg";
                };
              };
            };
          };
        };
      };
      nodev."/" = { fsType = "tmpfs"; mountOptions = ["size=25%" "mode=755"]; };
      lvm_vg.btrfs_vg = {
        type = "lvm_vg";
        lvs.root = {
          size = "100%FREE";
          content = {
            type = "btrfs";
            extraArgs = ["-f"];
            subvolumes = {
              "/root" = {};
              "/persist" = { mountOptions = ["subvol=persist" "noatime"]; mountpoint = "/persist"; };
              "/nix" = { mountOptions = ["subvol=nix" "noatime"]; mountpoint = "/nix"; };
            };
          };
        };
      };
    };
  };
}
