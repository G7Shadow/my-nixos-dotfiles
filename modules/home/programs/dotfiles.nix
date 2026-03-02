{self, ...}: {
  flake.homeModules.dotfiles = {config, ...}: let
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
    };
  in {
    home.file =
      builtins.mapAttrs
      (name: subpath: {
        source = create_symlink "${dotfiles}/${subpath}";
        target = ".config/${name}";
      })
      configs;
  };
}
