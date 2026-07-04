{ self, inputs, ... }: {
  flake.nixosModules.general = { pkgs, config, ... }: {
    imports = [
      self.nixosModules.extra_hjem
      inputs.nix-index-database.nixosModules.nix-index
    ];

    programs.nix-index-database.comma.enable = true;

    users.users."${config.preferences.user.name}" = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      shell = self.packages.${pkgs.system}.environment;
      hashedPasswordFile = "/persist/passwd";
      initialPassword = "12345";
    };

    users.groups."${config.preferences.user.name}" = { };

    security.sudo.extraRules = [
      {
        users = [ config.preferences.user.name ];
        commands = [
          {
            command = "ALL";
            options = [ "SETENV" ];
          }
        ];
      }
    ];

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      self.packages.${pkgs.system}.environment
      self.packages.${pkgs.system}.git
      tree
      direnv
    ];

    programs.direnv = {
      enable = true;
      silent = false;
      loadInNixShell = true;
      nix-direnv.enable = true;
    };

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
