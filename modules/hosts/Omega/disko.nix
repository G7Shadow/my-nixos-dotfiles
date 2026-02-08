{
  flake.diskoConfigurations.hostOmega = {
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = "/dev/sda";

          content = {
            type = "gpt";

            partitions = {
              # EFI System Partition (shared with Windows)
              ESP = {
                priority = 1;
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = ["fmask=0077" "dmask=0077"];
                };
              };

              # Windows partitions (sda2, sda3, sda4) - not defined, disko skips them

              # NixOS Root Partition (sda5)
              root = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                  mountOptions = ["relatime"];
                };
              };
            };
          };
        };
      };
    };
  };
}
