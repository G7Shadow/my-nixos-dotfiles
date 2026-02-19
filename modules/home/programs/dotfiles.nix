{
  flake.homeModules.dotfiles = {config, ...}: let
    dotfiles = "${config.home.homeDirectory}/my-nixos-dotfiles/modules/home/programs/config";
    create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

    configs = {
      hypr = "hypr";
      rofi = "rofi";
      waybar = "waybar";
      kitty = "kitty";
      matugen = "matugen";
      nvim = "nvim";
      tmux = "tmux";
    };
  in {
    xdg.configFile =
      builtins.mapAttrs
      (name: subpath: {
        source = create_symlink "${dotfiles}/${subpath}";
        recursive = true;
      })
      configs;
  };
}
