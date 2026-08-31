{ moduleWithSystem, ... }: {
  flake.nixosModules.spicetify = moduleWithSystem (
    { ... }:
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
      # The NixOS spotify lives read-only in /nix/store, but `spicetify apply` must WRITE
      # to the app files. So we run spotify from a user-writable copy rooted at
      # ~/.local/share/spotify (the same model spicetify's docs recommend for
      # spotify-launcher). The source wrapper (spotify + .spotify-wrapped + resources) is
      # copied from the store; only its final `exec` is repointed at the writable copy so
      # the spiced app is actually the one running.
      storeSpotify = "${pkgs.spotify}/share/spotify";
      spotifyRoot = "$HOME/.local/share/spotify";
      spicetify = "${pkgs.spicetify-cli}/bin/spicetify";
      # Copy-if-missing bootstrap for the writable spotify app dir.
      copySpotify = ''
        dst=$HOME/.local/share/spotify
        if [ ! -e "$dst/.spotify-wrapped" ]; then
          mkdir -p "$HOME/.local/share"
          rm -rf "$dst"
          cp -r "${storeSpotify}" "$dst"
          chmod -R u+w "$dst"
          # Repoint the copied wrapper's exec at the writable copy (only ".spotify-wrapped"
          # appears there; every other store path is a legit absolute lib path to keep).
          sed -i 's|${storeSpotify}/\.spotify-wrapped|'"$dst"'/.spotify-wrapped|' "$dst/spotify"
        fi
      '';
      # The user launcher replaces `pkgs.spotify`: bootstrap the writable copy, then run it.
      spotifyLauncher = pkgs.writeShellScriptBin "spotify" ''
        set -eu
        ${copySpotify}
        exec "$dst/spotify" "$@"
      '';
      # Seeds a mutable spicetify config (spicetify rewrites config-xpui.ini itself on
      # every `config`/`apply`/`refresh`, so it must NOT be a read-only store symlink),
      # then does the one-time `backup apply` that guts the writable spotify copy. From
      # there the existing wallust theme-apply.sh hook switches color_scheme +
      # `spicetify refresh` dynamically on SUPER+T.
      seedScript = pkgs.writeShellScript "spicetify-seed" ''
        set -eu
        cfg="$HOME/.config/spicetify"
        ini="$cfg/config-xpui.ini"

        ${copySpotify}
        spotify_path="$dst"

        if [ ! -e "$cfg" ]; then
          mkdir -p "$cfg"
        fi

        if [ ! -e "$ini" ]; then
          cat > "$ini" <<EOF
        [Setting]
        spotify_path = $spotify_path
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

        # One-shot: only spice on the first ever seed (subsequent boots skip), since a
        # late re-apply would need spotify closed. Late theme switches are handled by
        # theme-apply.sh -> `spicetify refresh`.
        if [ ! -e "$cfg/.seeded" ]; then
          if ${spicetify} backup apply >/dev/null 2>&1; then
            touch "$cfg/.seeded"
          fi
        fi
      '';
    in
    {
      # Install the spicetify CLI (so `spicetify config/apply/refresh`, used by wallust
      # theme-apply.sh, works at runtime) and the spotify launcher (which runs spotify
      # from a writable copy that apply/refresh can patch). Link in the Sleek theme; it
      # is read-only to spicetify and color.ini has one section per wallust scheme so
      # theme-apply.sh's name-matching `spicetify config color_scheme <name>` hits.
      hjem.users."${user}" = {
        packages = with pkgs; [
          spicetify-cli
          spotifyLauncher
        ];
        xdg.config.files = {
          "spicetify/Themes/Sleek/user.css".source = ./config/spicetify/Themes/Sleek/user.css;
          "spicetify/Themes/Sleek/color.ini".source = ./config/spicetify/Themes/Sleek/color.ini;
        };
      };

      # The mutable spicetify config + the writable spotify copy (which spicetify guts with
      # a backup/apply) must survive reboots, especially under impermanence (tmpfs root).
      persistance.data.directories = [
        ".config/spicetify"
        ".local/share/spotify"
      ];

      system.activationScripts.spicetifySeed = {
        text = ''
          runuser -u ${user} -- ${seedScript} || true
        '';
        deps = [ ];
      };
    }
  );
}
