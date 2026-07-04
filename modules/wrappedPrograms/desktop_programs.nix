{ self, ... }: {
  flake.nixosModules.desktop-packages = { ... }: {
    imports = [
      self.nixosModules.dev
      self.nixosModules.cli-tools
      self.nixosModules.desktop-apps
      self.nixosModules.desktop-utils
    ];
  };
}
