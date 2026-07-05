{ ... }:
{
  flake.nixosModules.neovim =
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
    in
    {
      hjem.users."${user}" = {
        packages = [ pkgs.neovim ];
        environment.sessionVariables.EDITOR = "nvim";
      };
    };
}
