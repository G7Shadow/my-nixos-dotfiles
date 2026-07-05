{ ... }: {
  flake.nixosModules.gaming = { pkgs, ... }: {
    programs = {
      gamemode.enable = true;
      steam = {
        enable = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
      };
    };

    persistance.cache.directories = [
      ".local/share/Steam"
    ];

    nix.settings = {
      substituters = [
        "https://nix-gaming.cachix.org"
      ];
      trusted-public-keys = [
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      ];
    };
  };
}
