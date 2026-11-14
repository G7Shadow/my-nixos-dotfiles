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

      security.sudo.extraConfig = ''
        Defaults lecture=never
      '';

      users.users."${config.preferences.user.name}" = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
          "i2c"
        ];
        shell = self'.packages.environment;
        hashedPasswordFile = "/persist/passwd";
      };

      # Creates the i2c group and the /dev/i2c-* udev rules referenced by the
      # "i2c" group above. Without it ddcutil cannot control external monitor
      # brightness (EACCES on /dev/i2c-*).
      hardware.i2c.enable = true;

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
        ".config"
        ".vscode-oss"
        ".vscode-oss-shared"
        ".themes"
        "my-nixos-dotfiles"
        "Documents"
        "Downloads"
        "Projects"
        ".local/share/opencode"
        ".local/state/opencode"
      ];
      persistance.data.files = [
        ".gitconfig"
        ".zsh_history"
      ];

      persistance.cache.directories = [
        ".local/share/zoxide"
        ".local/share/direnv"
        ".local/share/nvim"
        ".mozilla"
        ".cache/wallust"
        ".cache/matugen"
      ];

      persistance.cache.files = [
        ".cache/nvim-dynamite-theme"
      ];
    }
  );
}
