{ moduleWithSystem, ... }:
{
  flake.nixosModules.desktop-apps = moduleWithSystem (
    { inputs', ... }:
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
      # Noctalia-style zen theming: the profile's chrome files stay small and
      # stable; wallust regenerates the colors into ~/.cache/wallust/zen-browser
      # and the profile just @imports them. Profile's own tweaks are preserved
      # (they go after the import and therefore win).
      zenSetup = ''
        zenThemeDir="/home/${user}/.cache/wallust/zen-browser"
        mkdir -p "$zenThemeDir"
        for profile in /home/${user}/.zen/*.Default\ Profile; do
            [ -d "$profile" ] || continue
            mkdir -p "$profile/chrome"
            for f in userChrome userContent; do
                target="$profile/chrome/$f.css"
                import_line="@import \"$zenThemeDir/$f.css\";"
                if [ -f "$target" ] && grep -qF "$zenThemeDir/$f.css" "$target"; then
                    : # import already present
                elif [ -f "$target" ] && [ "$(head -n1 "$target")" = "* {" ]; then
                    # old full wallust-generated file: replace with the import
                    echo "$import_line" > "$target"
                elif [ -f "$target" ]; then
                    # custom css: prepend the import so custom rules still win
                    { echo "$import_line"; cat "$target"; } > "${target}.tmp" && mv "${target}.tmp" "$target"
                else
                    echo "$import_line" > "$target"
                fi
            done
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
