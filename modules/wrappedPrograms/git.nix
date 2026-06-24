{ config, ... }:
{
  flake.nixosModules.git =
    { lib, ... }:
    let
      user = config.preferences.user.name;
    in
    {
      hjem.users."${user}".files.".gitconfig" = {
        generator = lib.generators.toGitINI; # ← no `{ }` here
        value = {
          user = {
            name = "G7Shadow";
            email = "l.jeremy.822001@gmail.com";
          };
          init.defaultBranch = "main";
          pull.rebase = false;
          core.editor = "nvim";
        };
      };
    };
}
