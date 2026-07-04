{ self, ... }: {
  flake.nixosModules.general = { config, ... }: {
    imports = [
      self.nixosModules.extra_hjem
    ];

    persistance.data.directories = [
      ".ssh"
      ".config/nvim"
    ];

    persistance.cache.directories = [
      ".local/share/zoxide"
      ".local/share/direnv"
      ".local/share/nvim"
      ".mozilla"
      ".cache/wallust"
      ".cache/matugen"
    ];
  };
}
