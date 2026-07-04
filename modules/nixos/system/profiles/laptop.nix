{ self, ... }:
{
  flake.nixosModules.profile-laptop = {
    imports = with self.nixosModules; [
      drivers-amd
      audio
      auto-cpufreq
    ];
  };
}
