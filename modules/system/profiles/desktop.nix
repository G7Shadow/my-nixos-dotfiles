{ self, ... }: {
  flake.nixosModules.profile-desktop = {
    imports = with self.nixosModules; [
      audio
      hyprland
      auto-cpufreq
      virtualization
    ];
  };
}
