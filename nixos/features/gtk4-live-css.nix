{ ... }:
{
  flake.nixosModules.gtk4LiveCss = { ... }: {
    nixpkgs.overlays = [
      (import ../../overlays/gtk4-live-css.nix)
    ];
  };
}
