{ moduleWithSystem, ... }:
{
  flake.nixosModules.desktop-apps = moduleWithSystem (
    { inputs', ... }:
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
      # Mirrors the Noctalia Zen template: discover every profile, ensure its
      # chrome dir exists, and enable native custom-stylesheet loading via
      # user.js (which Zen applies on next full restart).
      zenSetup = ''
        for profile in /home/${user}/.zen/*.Default\ Profile; do
            [ -d "$profile" ] || continue
            mkdir -p "$profile/chrome"
            touch "$profile/chrome/userChrome.css" "$profile/chrome/userContent.css"
            if [ ! -f "$profile/user.js" ] \
               || ! grep -q "toolkit.legacyUserProfileCustomizations.stylesheets" "$profile/user.js"; then
              printf '%s\n' \
                'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' \
                'user_pref("devtools.chrome.enabled", true);' >> "$profile/user.js"
            fi
        done
      '';
    in
    {
      services.gvfs.enable = true;

      hjem.users."${user}".packages = with pkgs; [
        inputs'.zen-browser.packages.default
        brave
        (vesktop.override { withSystemVencord = true; })
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

      system.activationScripts.zenChromeSetup = {
        text = zenSetup;
        deps = [ ];
      };
    }
  );
}
