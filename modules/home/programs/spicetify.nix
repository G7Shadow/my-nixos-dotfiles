{
  flake.homeModules.spicetify = {
    pkgs,
    inputs,
    ...
  }: let
    spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  in {
    imports = [inputs.spicetify-nix.homeManagerModules.default];

    programs.spicetify = {
      enable = true;

      # Use Sleek theme
      theme = spicePkgs.themes.sleek;

      # Enable extensions
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
