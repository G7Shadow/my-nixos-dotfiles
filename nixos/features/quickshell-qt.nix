{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    inputs.quickshell.packages.${pkgs.system}.default
    qt6.qtwayland
  ];

  environment.sessionVariables = {
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  };
}
