{
  inputs,
  lib,
  ...
}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: let
    fishConf =
      pkgs.writeText "config.fish"
      ''
        set -gx EDITOR nvim

        set fish_greeting
        fish_vi_key_bindings

        # Aliases
        alias v="nvim"
        alias t="tmux"
        alias ta="tmux attach || tmux new"
        alias gs="git status"
        alias ga="git add"
        alias gc="git commit"
        alias gp="git push"
        alias gl="git log --oneline"
        alias gd="git diff"
        alias ls="eza --icons"
        alias ll="eza -l --icons"
        alias la="eza -la --icons"
        alias lt="eza --tree --icons"
        alias cat="bat"

        # Init hooks
        ${lib.getExe pkgs.zoxide} init fish | source
        ${lib.getExe pkgs.starship} init fish | source

        if type -q direnv
            direnv hook fish | source
        end

        if type -q fzf
            fzf --fish | source
        end

        if type -q nitch; and not set -q TMUX; and not set -q NITCH_RAN
            set -gx NITCH_RAN 1
            nitch
        end
      '';
  in {
    packages.fish = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.fish;
      runtimeInputs = [
        pkgs.zoxide
        pkgs.starship
        pkgs.direnv
        pkgs.fzf
        pkgs.nitch
        pkgs.eza
        pkgs.bat
      ];
      flags = {
        "-C" = "source ${fishConf}";
      };
    };
  };
}
