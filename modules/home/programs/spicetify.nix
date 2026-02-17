{
  flake.homeModules.spicetify = {
    pkgs,
    inputs,
    ...
  }: let
    spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
  in {
    imports = [inputs.spicetify-nix.homeManagerModules.default];

    programs.spicetify = {
      enable = true;

      # We'll use a custom theme that Matugen will populate
      theme = spicePkgs.themes.Sleek;

      # Optional: Enable extensions you want
      enabledExtensions = with spicePkgs.extensions; [
        adblock
        hidePodcasts
        shuffle
        bookmark
        keyboardShortcut
      ];

      # Optional: Enable custom apps
      enabledCustomApps = with spicePkgs.apps; [
        # lyrics-plus
      ];
    };
  };
}
