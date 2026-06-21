# modules/home/programs/neovim.nix
{ self, ... }:
{
  flake.nixosModules.neovim =
    { pkgs, ... }:
    {
      hjem.users.jeremyl = {
        packages = [ pkgs.neovim ];
        environment.sessionVariables.EDITOR = "nvim";
      };
    };
}
