{
  flake.homeModules.git = { pkgs, ... }: {
    programs.git = {
      enable = true;
      
      settings = {
        user.name = "G7Shadow";
        user.email = "l.jeremy.822001@gmail.com";
        init.defaultBranch = "main";
        pull.rebase = false;
        core.editor = "nvim";
      };
    };
  };
}
