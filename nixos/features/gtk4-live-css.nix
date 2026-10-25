{ ... }:
{
  flake.nixosModules.gtk4LiveCss = { ... }: {
    nixpkgs.overlays = [
      (import ../../overlays/_gtk4-live-css.nix)
    ];
  };
}
