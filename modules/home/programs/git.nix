# modules/home/programs/git.nix
{ self, ... }:
{
  flake.nixosModules.git =
    { lib, ... }:
    {
      hjem.users.jeremyl.files.".gitconfig" = {
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
