{ moduleWithSystem, ... }: {
  flake.nixosModules.spicetify = moduleWithSystem (
    { ... }:
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
      spotifyPath = "${pkgs.spotify}/share/spotify";
      spicetify = "${pkgs.spicetify-cli}/bin/spicetify";
      # Seeds a mutable spicetify config (spicetify rewrites config-xpui.ini itself on
      # every `config`/`apply`/`refresh`, so it must NOT be a read-only store symlink),
      # then does the one-time `backup apply` that guts the vanilla spotify. From there
      # the existing wallust theme-apply.sh hook switches color_scheme + `spicetify refresh`
      # dynamically on SUPER+T.
      seedScript = pkgs.writeShellScript "spicetify-seed" ''
        set -eu
        cfg="$HOME/.config/spicetify"
        ini="$cfg/config-xpui.ini"

        if [ ! -e "$cfg" ]; then
          mkdir -p "$cfg"
        fi

        if [ ! -e "$ini" ]; then
          cat > "$ini" <<EOF
        [Setting]
        spotify_path = ${spotifyPath}
        prefs_path = $cfg/prefs
        check_spicetify_update = false
        current_theme = Sleek
        color_scheme = noir
        inject_css = true
        inject_theme_js = true
        replace_colors = true
        overwrite_assets = false
EOF
        fi

        # One-shot: only spice if spotify hasn't been spiced yet (our marker is the
        # config being present AND the spotify backup missing). Late switches are
        # handled by theme-apply.sh -> `spicetify refresh`.
        if [ ! -e "$cfg/xpui.js.bak" ] && [ ! -d "$cfg/spicetify_tmp" ]; then
          ${spicetify} backup apply >/dev/null 2>&1 || true
        fi
      '';
    in
    {
      # Install the spicetify CLI (so `spicetify config/apply/refresh`, used by wallust
      # theme-apply.sh, works at runtime against the vanilla spotify), and link in the
      # Sleek theme. The theme is read-only to spicetify (apply/refresh only read it) and
      # color.ini has one section per wallust scheme so theme-apply.sh's name-matching
      # `spicetify config color_scheme <name>` hits.
      hjem.users."${user}" = {
        packages = with pkgs; [
          spicetify-cli
        ];
        xdg.config.files = {
          "spicetify/Themes/Sleek/user.css".source = ./config/spicetify/Themes/Sleek/user.css;
          "spicetify/Themes/Sleek/color.ini".source = ./config/spicetify/Themes/Sleek/color.ini;
        };
      };

      # The mutable spicetify config + spiced app + backups must survive reboots,
      # especially under impermanence (Omega's tmpfs root).
      persistance.data.directories = [ ".config/spicetify" ];

      system.activationScripts.spicetifySeed = {
        text = ''
          runuser -u ${user} -- ${seedScript} || true
        '';
        deps = [ ];
      };
    }
  );
}
