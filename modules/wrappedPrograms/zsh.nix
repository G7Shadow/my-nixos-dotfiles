{ inputs, lib, ... }: {
  perSystem =
    { pkgs, self', ... }:
    let
      zshrc = pkgs.writeText "zshrc" ''
        export EDITOR=nvim
        autoload -Uz compinit && compinit

        source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

        alias v="nvim" t="tmux" ta="tmux attach || tmux new"
        alias gs="git status" ga="git add" gc="git commit"
        alias gp="git push" gl="git log --oneline" gd="git diff"
        alias ls="eza --icons" ll="eza -l --icons"
        alias la="eza -la --icons" lt="eza --tree --icons"
        alias cat="bat" cd="z"

        eval "$(zoxide init zsh)"
        eval "$(starship init zsh)"
        eval "$(direnv hook zsh)"
        eval "$(fzf --zsh)"

        if command -v nitch &>/dev/null && [ -z "$TMUX" ] && [ -z "$NITCH_RAN" ]; then
          export NITCH_RAN=1
          nitch
        fi
      '';

      starshipToml = pkgs.writeText "starship.toml" ''
        command_timeout = 500
        scan_timeout = 100
      '';

      zdotdir = pkgs.runCommand "zdotdir" { } ''
        mkdir -p $out
        cp ${zshrc} $out/.zshrc
      '';

      zshLauncher = pkgs.writeShellScriptBin "zsh" ''
        export ZDOTDIR=${zdotdir}
        export STARSHIP_CONFIG=${starshipToml}
        exec ${pkgs.zsh}/bin/zsh "$@"
      '';
    in
    {
      packages.zsh = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = zshLauncher;
        runtimeInputs = with pkgs; [
          zsh
          zoxide
          fzf
          starship
          direnv
          eza
          bat
          nitch
          zsh-autosuggestions
          zsh-syntax-highlighting
        ];
      };
    };
}
