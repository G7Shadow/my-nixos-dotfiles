{
  moduleWithSystem,
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.general = moduleWithSystem (
    { self', ... }:
    { pkgs, config, ... }: {
      imports = [
        self.nixosModules.extra_hjem
        inputs.nix-index-database.nixosModules.nix-index
      ];

      programs.nix-index-database.comma.enable = true;
      programs.fish.enable = true;

      users.users."${config.preferences.user.name}" = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
        shell = self'.packages.environment;
        hashedPasswordFile = "/persist/passwd";
        initialPassword = "12345";
      };

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      nixpkgs.config.allowUnfree = true;
      environment.systemPackages = with pkgs; [
        self'.packages.environment
        self'.packages.git
        self'.packages.nh
        tree
        direnv
      ];

      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          stdenv.cc.cc.lib
          zlib
          brotli
          unixodbc
          zstd
          glib
          qt6.qtbase
          qt6.qtdeclarative
        ];
      };

      programs.direnv = {
        enable = true;
        silent = false;
        loadInNixShell = true;
        nix-direnv.enable = true;
      };

      persistance.data.directories = [
        ".ssh"
        ".config/nvim"
        "my-nixos-dotfiles"
      ];

      persistance.cache.directories = [
        ".local/share/zoxide"
        ".local/share/direnv"
        ".local/share/nvim"
        ".local/share/fish"
        ".mozilla"
        ".cache/wallust"
        ".cache/matugen"
      ];
    }
  );
}
