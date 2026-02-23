{ self, ... }: {
  flake.nixosModules.profile-server = {
    imports = with self.nixosModules; [
      auto-cpufreq
      # Add audio, virtualization etc. as needed per host
    ];
  };
}
