{ moduleWithSystem, ... }:
{
  flake.nixosModules.desktop-apps = moduleWithSystem (
    { inputs', ... }:
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
      zenProfiles = [
        "hz3ab4gh.Default Profile"
        "4hnn7g3c.Default Profile"
      ];
      chromeDir = "/home/${user}/my-nixos-dotfiles/nixos/features/config/zen";
      mkProfileLinks = builtins.concatStringsSep "\n" (
        map (profile: ''
          mkdir -p "/home/${user}/.zen/${profile}/chrome"
          cp "${chromeDir}/userChrome.js" "/home/${user}/.zen/${profile}/chrome/userChrome.js"
          printf '%s\n' '// Enable userChrome.css and userChrome.js loading' 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' > "/home/${user}/.zen/${profile}/user.js"
        '') zenProfiles
      );
    in
    {
      services.gvfs.enable = true;

      hjem.users."${user}".packages = with pkgs; [
        inputs'.zen-browser.packages.default
        discord
        vesktop
        spotify
        obsidian
        netflix
        localsend
        prismlauncher
        zed-editor
        obs-studio
        thunar
        nautilus
        file-roller
        virt-manager
      ];

      system.activationScripts.zenHotReload = {
        text = mkProfileLinks;
        deps = [ ];
      };
    }
  );
}
