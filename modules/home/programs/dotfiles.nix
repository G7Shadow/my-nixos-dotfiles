{ self, lib, ... }:
{
  flake.homeModules.dotfiles =
    { config, lib, ... }:
    let
      dotfiles = "${config.home.homeDirectory}/my-nixos-dotfiles/modules/home/programs/config";
      create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

      configs = {
        hypr = "hypr";
        ags = "ags";
        rofi = "rofi";
        waybar = "waybar";
        kitty = "kitty";
        swaync = "swaync";
        matugen = "matugen";
        nvim = "nvim";
        tmux = "tmux";
        quickshell = "quickshell";
      };
    in
    {
      home.file = lib.mapAttrs' (
        name: subpath:
        lib.nameValuePair ".config/${name}" {
          source = create_symlink "${dotfiles}/${subpath}";
        }
      ) configs;
    };
}
