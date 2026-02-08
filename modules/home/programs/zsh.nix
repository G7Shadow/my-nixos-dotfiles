{
  flake.homeModules.zsh = {pkgs, ...}: {
    programs.zsh = {
      enable = true;
      autosuggestion = {
        enable = true;
        strategy = ["history"];
      };
      syntaxHighlighting.enable = true;
      enableCompletion = true;

      shellAliases = {
        # Basic
        v = "nvim";
        t = "tmux";
        ta = "tmux attach || tmux new";

        # Git aliases
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

        # Other useful aliases
        cat = "bat";
        cd = "z";

        # NixOS shortcuts
        nrs = "sudo nixos-rebuild switch --flake ~/my-nixos-dotfiles#Omega";
        nrt = "sudo nixos-rebuild test --flake ~/my-nixos-dotfiles#Omega";
        nfu = "nix flake update";
      };

      initContent = ''
        # Only run nitch in interactive, non-tmux shells
        if command -v nitch &> /dev/null && [ -z "$TMUX" ] && [ -z "$NITCH_RAN" ]; then
          export NITCH_RAN=1
          nitch
        fi

        # Fast directory jumping
        eval "$(zoxide init zsh)"
      '';
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        command_timeout = 500;
        scan_timeout = 10;
      };
    };
  };
}
