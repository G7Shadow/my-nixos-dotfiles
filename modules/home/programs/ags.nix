{self, ...}: {
  flake.homeModules.ags = {
    pkgs,
    inputs,
    ...
  }: {
    imports = [inputs.ags.homeManagerModules.default];

    programs.ags = {
      enable = true;
      extraPackages = [
        inputs.astal.packages.${pkgs.system}.battery
        inputs.astal.packages.${pkgs.system}.wireplumber
        inputs.astal.packages.${pkgs.system}.network
        inputs.astal.packages.${pkgs.system}.mpris
        inputs.astal.packages.${pkgs.system}.hyprland
        inputs.astal.packages.${pkgs.system}.notifd
      ];
    };
  };
}
