{ self, ... }: {
  flake.homeModules.zsh = { pkgs, ... }: {
    programs.zsh = {
      enable            = true;
      autosuggestion    = {
        enable   = true;
        strategy = [ "history" ];
      };
      syntaxHighlighting.enable = true;
      enableCompletion          = true;

      shellAliases = {
        # Quick launchers
        v  = "nvim";
        t  = "tmux";
        ta = "tmux attach || tmux new";

        # Git
        gs = "git status";
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gl = "git log --oneline";
        gd = "git diff";

        # Eza (modern ls)
        ls = "eza --icons";
        ll = "eza -l --icons";
        la = "eza -la --icons";
        lt = "eza --tree --icons";

        # Better defaults
        cat = "bat";
        cd  = "z";
      };

      initContent = ''
        # Show system info once per shell, only outside tmux
        if command -v nitch &> /dev/null && [ -z "$TMUX" ] && [ -z "$NITCH_RAN" ]; then
          export NITCH_RAN=1
          nitch
        fi

        eval "$(zoxide init zsh)"
      '';
    };

    programs.fzf = {
      enable              = true;
      enableZshIntegration = true;
    };

    programs.zoxide = {
      enable               = true;
      enableZshIntegration = true;
    };

    programs.starship = {
      enable               = true;
      enableZshIntegration = true;
      settings = {
        command_timeout = 500;
        scan_timeout    = 10;
      };
    };

    programs.direnv = {
      enable               = true;
      enableZshIntegration = true;
      nix-direnv.enable    = true;
    };
  };
}
