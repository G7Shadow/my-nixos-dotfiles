{ moduleWithSystem, ... }: {
  flake.nixosModules.gaming = moduleWithSystem (
    { ... }:
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
      homeDir = config.users.users.${user}.home;
      # Prism instance 26.3 mod folder (persisted via impermanence)
      modsDir = "${homeDir}/.local/share/PrismLauncher/instances/26.3/minecraft/mods";

      # Pinned Modrinth primary builds for Minecraft 26.3 (Fabric). SHA-512 from
      # the Modrinth API; fetched at build time so mods live in /nix/store.
      minecraftModJars = [
        {
          name = "sodium-fabric-0.9.2+mc26.3.jar";
          url = "https://cdn.modrinth.com/data/AANobbMI/versions/bAZQdGpg/sodium-fabric-0.9.2%2Bmc26.3.jar";
          sha512 = "f3f260f204b8ce5e8777c2c73f537956755ec61f3817b0b78b5e5568e8aa40f14891f146475075109747665c7c88a45ca0ca9a8df3c68d79c58ecdaa8d8c4b93";
        }
        {
          name = "iris-fabric-1.11.6+mc26.3.jar";
          url = "https://cdn.modrinth.com/data/YL57xq9U/versions/bAdKrpw8/iris-fabric-1.11.6%2Bmc26.3.jar";
          sha512 = "cd0fdc5a275a851b3d72e3e699c957671f293f5c87951736ad83adcdabaa58f533e9791110a227c7817b312269c32c063121b183a39d8c11a22e55d2c76cdb25";
        }
        {
          name = "fabric-api-0.161.0+26.3.jar";
          url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/bNnaTiuM/fabric-api-0.161.0%2B26.3.jar";
          sha512 = "ed6b2586d6fde11fde8472f5a527c51e99b67026e46f94d4bfd85e7e28ce5ee299173ee16ad576ceb51f39f98d30a811086a6deb1a86a524859cc16e12da109d";
        }
      ];

      # The ISP's DPI throttles Modrinth; retry on the fetchurl until a clean
      # route (VPN/hotspot) lets the download through.
      minecraftMods = pkgs.linkFarm "minecraft-mods-26.3" (map
        (j: {
          inherit (j) name;
          path = pkgs.fetchurl {
            inherit (j) url sha512;
            curlOpts = "--retry 20 --retry-all-errors --retry-delay 3 --connect-timeout 15 --max-time 120";
          };
        })
        minecraftModJars);
    in {
      programs = {
        gamemode.enable = true;
        steam = {
          enable = true;
          extraCompatPackages = [ pkgs.proton-ge-bin ];
        };
      };

      persistance.data.directories = [
        ".local/share/PrismLauncher"
      ];

      persistance.cache.directories = [
        ".local/share/Steam"
      ];

      system.activationScripts.minecraftMods.text = ''
        mkdir -p ${modsDir}
        ln -sfn ${minecraftMods}/* ${modsDir}/
      '';

      nix.settings = {
        substituters = [
          "https://nix-gaming.cachix.org"
        ];
        trusted-public-keys = [
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        ];
      };
    }
  );
}
