final: prev: {
  gtk4 = prev.gtk4.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./gtk4-live-css/gtk4-user-css-live-reload.patch
    ];
  });
}
