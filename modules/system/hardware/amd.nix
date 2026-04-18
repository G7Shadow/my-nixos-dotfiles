{ ... }:
{
  flake.nixosModules.drivers-amd =
    { pkgs, ... }:
    {
      hardware.cpu.amd.updateMicrocode = true;
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          amdvlk
          rocmPackages.clr.icd
        ];
      };
    };
}
