{ inputs, lib, ... }: {
  perSystem =
    { pkgs, self', ... }:
    let
      zshrc = pkgs.writeText "zshrc" ''
        export EDITOR=nvim
        export PATH="$HOME/.local/bin:$PATH"
        export HISTFILE="$HOME/.zsh_history"
        export HISTSIZE=10000
        export SAVEHIST=10000
        setopt SHARE_HISTORY APPEND_HISTORY INC_APPEND_HISTORY
        autoload -Uz compinit && compinit

        source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

        alias v="nvim" t="tmux" ta="tmux attach || tmux new"
        alias gs="git status" ga="git add" gc="git commit"
        alias gp="git push" gl="git log --oneline" gd="git diff"
        alias ls="eza --icons" ll="eza -l --icons"
        alias la="eza -la --icons" lt="eza --tree --icons"
        alias cat="bat" cd="z"

        eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"
        eval "$(${pkgs.starship}/bin/starship init zsh)"
        eval "$(${pkgs.direnv}/bin/direnv hook zsh)"
        eval "$(${pkgs.fzf}/bin/fzf --zsh)"

        if [ -x "${pkgs.nitch}/bin/nitch" ] && [ -z "$TMUX" ] && [ -z "$NITCH_RAN" ]; then
          export NITCH_RAN=1
          ${pkgs.nitch}/bin/nitch
        fi
      '';

      zdotdir = pkgs.runCommand "zdotdir" { } ''
        mkdir -p $out
        cp ${zshrc} $out/.zshrc
      '';
    in
    {
      packages.zsh = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.zsh;
        env = {
          ZDOTDIR = "${zdotdir}";
        };
      };
    };
}
