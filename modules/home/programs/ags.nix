{self, ...}: {
  flake.homeModules.ags = {
    pkgs,
    inputs,
    ...
  }: {
    imports = [inputs.ags.homeManagerModules.default];

    programs.ags = {
      enable = true;
      extraPackages = with inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}; [
        battery
        wireplumber
        network
        mpris
        hyprland
        notifd
        apps
      ];
    };
  };
}
