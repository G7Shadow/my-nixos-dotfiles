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
        ];
        shell = self'.packages.environment;
        hashedPasswordFile = "/persist/passwd";
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
        ".config"
        ".vscode-oss"
        ".vscode-oss-shared"
        ".themes"
        "my-nixos-dotfiles"
        "Downloads"
        ".local/share/opencode"
      ".local/state/opencode"
      ];
      persistance.data.files = [
        ".gitconfig"
        ".zsh_history"
      ];

      persistance.cache.directories = [
        ".zen"
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
