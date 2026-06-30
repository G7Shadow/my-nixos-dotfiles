{ ... }:
{
  flake.nixosModules.cli-tools =
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
    in
    {
      hjem.users."${user}".packages = with pkgs; [
        kitty
        htop
        btop
        lsof
        tree
        wget
        zoxide
        ripgrep
        fzf
        bat
        eza
        fd
        lazygit
        tmux
      ];
    };
}
