{ ... }:
{
  flake.nixosModules.zsh =
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
    in
    {
      programs.zsh.enable = true;

      hjem.users."${user}" = {
        environment.sessionVariables.QMLLS_BUILD_DIRS =
          "/etc/profiles/per-user/${user}/lib/qt-6/qml";

        packages = with pkgs; [
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

        files.".zshrc" = {
          text = ''

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
        };

        files.".config/starship.toml" = {
          generator = (pkgs.formats.toml { }).generate "starship.toml";
          value = {
            command_timeout = 500;
            scan_timeout = 10;
          };
        };
      };
    };
}
