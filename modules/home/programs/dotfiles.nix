# modules/home/programs/dotfiles.nix
{ ... }:
{
  flake.nixosModules.dotfiles =
    { ... }:
    {
      system.activationScripts.dotfileSymlinks =
        let
          dotfiles = "/home/jeremyl/my-nixos-dotfiles/modules/home/programs/config";
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
                ln -sfn "${dotfiles}/${sub}" "/home/jeremyl/.config/${name}"
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
