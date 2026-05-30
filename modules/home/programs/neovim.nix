{ self, ... }:
{
  flake.homeModules.neovim =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.neovim ];
      home.sessionVariables.EDITOR = "nvim";
      home.shellAliases = {
        vi = "nvim";
        vim = "nvim";
      };
    };
}
