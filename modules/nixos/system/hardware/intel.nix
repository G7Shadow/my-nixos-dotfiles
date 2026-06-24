{ ... }:
{
  flake.nixosModules.drivers-intel =
    { pkgs, ... }:
    {
      hardware.cpu.intel.updateMicrocode = true;
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          intel-media-driver
          vaapiIntel
        ];
      };
    };
}
