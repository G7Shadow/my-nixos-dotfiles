{ self, ... }: {
  flake.homeModules.dotfiles = { config, ... }: let
    dotfiles = "${config.home.homeDirectory}/my-nixos-dotfiles/modules/home/programs/config";
    symlink = path: config.lib.file.mkOutOfStoreSymlink path;

    link = subpath: {
      source    = symlink "${dotfiles}/${subpath}";
      recursive = true;
    };
  in {
    xdg.configFile = {
      hypr    = link "hypr";
      rofi    = link "rofi";
      waybar  = link "waybar";
      kitty   = link "kitty";
      matugen = link "matugen";
      nvim    = link "nvim";
      tmux    = link "tmux";
    };
  };
}
