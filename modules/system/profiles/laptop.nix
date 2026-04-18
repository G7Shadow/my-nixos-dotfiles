{ self, ... }:
{
  flake.nixosModules.profile-laptop = {
    imports = with self.nixosModules; [
      drivers-amd
      audio
      hyprland
      auto-cpufreq
      virtualization
    ];
  };
}
