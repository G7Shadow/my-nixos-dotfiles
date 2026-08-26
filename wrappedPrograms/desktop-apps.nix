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
        inputs'.zen-browser.packages.default
        discord
        vesktop
        spotify
        firefox
        obsidian
        netflix
        localsend
        prismlauncher
        zed-editor
        obs-studio
        thunar
        nautilus
        kdePackages.dolphin
        file-roller
        virt-manager
      ];
    }
  );
}
