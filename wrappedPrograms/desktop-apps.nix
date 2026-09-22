{ moduleWithSystem, ... }:
{
  flake.nixosModules.desktop-apps = moduleWithSystem (
    { inputs', ... }:
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
    in
    {
      services.gvfs.enable = true;

      hjem.users."${user}".packages = with pkgs; [
        brave
        (vesktop.override { withSystemVencord = true; })
        spotify
        vscodium
        obsidian
        netflix
        localsend
        prismlauncher
        zed-editor
        obs-studio
        thunar
        nautilus
        file-roller
        virt-manager
      ];
      deps = [ ];
    }
  );
}
