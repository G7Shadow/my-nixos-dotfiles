{ ... }:
{
  flake.nixosModules.dotfiles =
    { config, ... }:
    let
      user = config.preferences.user.name;
      dotfiles = "/home/${user}/my-nixos-dotfiles/modules/nixos/features/config";
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
        colorschemes = "colorschemes";
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
      system.activationScripts.dotfileSymlinks = {
        text = links;
        deps = [ ];
      };
    };
}
