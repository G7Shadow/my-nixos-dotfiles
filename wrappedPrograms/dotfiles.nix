{ ... }:
{
  flake.nixosModules.dotfiles =
    { config, ... }:
    let
      user = config.preferences.user.name;
      dotfiles = "/home/${user}/my-nixos-dotfiles/nixos/features/config";
      configs = {
        hypr = "hypr";
        quickshell = "quickshell";
        nvim = "nvim";
        kitty = "kitty";
        rofi = "rofi";
        swaync = "swaync";
        matugen = "matugen";
        waybar = "waybar";
        tmux = "tmux";
        uwsm = "uwsm";
        wallust = "wallust";
        colorschemes = "colorschemes";
      };
      links = builtins.concatStringsSep "\n" (
        builtins.attrValues (
          builtins.mapAttrs (name: sub: ''
            ln -sfn "${dotfiles}/${sub}" "/home/${user}/.config/${name}"
          '') configs
        )
      );
    in
    {
      system.activationScripts.dotfileSymlinks = {
        text = ''
          dotDir="/home/${user}/.config"
          persistDir="/persist/userdata/home/${user}/.config"
          mkdir -p "$dotDir"
          # If ~/.config is persisted but its bind mount is not up yet (first
          # switch after adding the persisted dir), mount it now so these
          # symlinks land on the persistent side instead of a tmpfs layer
          # that gets hidden once the systemd mount unit activates.
          if [ -d "$persistDir" ] && ! mountpoint -q "$dotDir"; then
            mount --bind "$persistDir" "$dotDir"
          fi
          ${links}
        '';
        deps = [ ];
      };
    };
}
