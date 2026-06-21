# modules/hosts/Omega/configuration.nix
{ inputs, self, ... }:
{
  flake.nixosConfigurations.Omega = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs self; };
    modules = [
      inputs.hjem.nixosModules.default
      self.nixosModules.hostOmega
      self.nixosModules.profile-laptop
      self.nixosModules.profile-desktop
    ];
  };

  flake.nixosModules.hostOmega =
    { pkgs, ... }:
    {
      boot = {
        loader.systemd-boot.enable = true;
        loader.systemd-boot.configurationLimit = 5;
        loader.timeout = 60;
        loader.efi.canTouchEfiVariables = true;
        supportedFilesystems = [ "ntfs" ];
      };

      services.logind.settings.Login = {
        HandleLidSwitch = "poweroff";
        HandleLidSwitchExternalPower = "lock";
        HandleLidSwitchDocked = "ignore";
      };

      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
        flake = "/home/jeremyl/my-nixos-dotfiles";
      };

      nix = {
        gc = {
          dates = "weekly";
          options = "--delete-older-than 14d";
        };
        optimise.automatic = true;
        settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
      };

      networking = {
        hostName = "Omega";
        networkmanager.enable = true;
      };

      time.timeZone = "America/Jamaica";
      i18n.defaultLocale = "en_US.UTF-8";

      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };

      security.sudo.enable = false;
      security.doas = {
        enable = true;
        extraRules = [
          {
            users = [ "jeremyl" ];
            keepEnv = true;
            persist = true;
          }
        ];
      };

      users.users.jeremyl = {
        isNormalUser = true;
        description = "Jeremy Lee";
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        shell = pkgs.zsh;
      };

      programs.zsh.enable = true;

      services.displayManager.gdm.enable = true;
      services.desktopManager.gnome.enable = true;

      nixpkgs.config.allowUnfree = true;

      environment.systemPackages = with pkgs; [ tree ];

      services = {
        flatpak.enable = true;
        fwupd.enable = true;
        fstrim.enable = true;
        udisks2.enable = true;
        dbus.enable = true;
      };

      zramSwap = {
        enable = true;
        algorithm = "zstd";
      };

      programs.steam = {
        enable = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
      };

      programs.gamemode.enable = true;

      nix.settings = {
        substituters = [
          "https://hyprland.cachix.org"
          "https://noctalia.cachix.org"
        ];
        trusted-substituters = [
          "https://hyprland.cachix.org"
          "https://noctalia.cachix.org"
        ];
        trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        ];
      };

      hjem.users.jeremyl = {
        user = "jeremyl";
        directory = "/home/jeremyl";
      };

      system.stateVersion = "25.05";
    };
}
