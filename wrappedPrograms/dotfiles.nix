{ ... }:
{
  flake.nixosModules.dotfiles =
    { config, ... }:
    let
      user = config.preferences.user.name;
      dotfiles = "/home/${user}/my-nixos-dotfiles/nixos/features/config";
      configs = {
        hypr = "hypr";
        quickshell = "quickshell";
        nvim = "nvim";
        kitty = "kitty";
        rofi = "rofi";
        swaync = "swaync";
        matugen = "matugen";
        waybar = "waybar";
        tmux = "tmux";
        uwsm = "uwsm";
        wallust = "wallust";
        colorschemes = "colorschemes";
      };
      links = builtins.concatStringsSep "\n" (
        builtins.attrValues (
          builtins.mapAttrs (name: sub: ''
            ln -sfn "${dotfiles}/${sub}" "/home/${user}/.config/${name}"
          '') configs
        )
      );
      # Launch Steam with -dev so theme-apply.sh's hot-reload trigger works.
      steamEntry = ''
        mkdir -p "/home/${user}/.local/share/applications"
        ln -sfn "${dotfiles}/applications/steam.desktop" "/home/${user}/.local/share/applications/steam.desktop"
      '';
    in
    {
      system.activationScripts.dotfileSymlinks = {
        text = links + "\n" + steamEntry;
        deps = [ ];
      };
    };
}
