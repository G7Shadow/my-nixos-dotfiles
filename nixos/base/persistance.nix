{ ... }: {
  flake.nixosModules.base = { lib, ... }: {
    options.persistance = {
      enable = lib.mkEnableOption "enable persistance";

      nukeRoot.enable = lib.mkEnableOption "Destroy /root on every boot";

      volumeGroup = lib.mkOption {
        type = lib.types.str;
        default = "btrfs_vg";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "jeremyl";
      };

      directories = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
      };

      files = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
      };

      data.directories = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
      };

      data.files = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
      };

      cache.directories = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
      };

      cache.files = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
      };
    };
  };
}
