{ ... }: {
  flake.nixosModules.gtk4LiveCss = { ... }: {
    nixpkgs.overlays = [
      (final: prev: {
        gtk4 = prev.gtk4.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./gtk4-user-css-live-reload.patch
          ];
        });
      })
    ];
  };
}
