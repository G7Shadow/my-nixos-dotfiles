{ config, ... }:
{
  flake.nixosModules.dotfiles =
    { ... }:
    let
      user = config.preferences.user.name;
      dotfiles = "/home/${user}/nixosConfig/modules/nixos/features/config";
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
          };
          links = builtins.concatStringsSep "\n" (
            builtins.attrValues (
              builtins.mapAttrs (name: sub: ''
                ln -sfn "${dotfiles}/${sub}" "/home/${user}/.config/${name}"
              '') configs
            )
          );
        in
        {
          text = links;
          deps = [ ];
        };
    };
}
