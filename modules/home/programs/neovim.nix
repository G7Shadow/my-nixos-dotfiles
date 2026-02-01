{
  flake.homeModules.neovim = { pkgs, ... }: {
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
    };
  };
}
