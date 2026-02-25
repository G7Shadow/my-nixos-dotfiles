{self, ...}: {
  flake.homeModules.spicetify = {pkgs, ...}: {
    home.activation.spicetify = {
      after = ["writeBoundary"];
      data = "";
      script = ''
        ${pkgs.spicetify-cli}/bin/spicetify config spotify_path ${pkgs.spotify}/share/spotify
        ${pkgs.spicetify-cli}/bin/spicetify config prefs_path $HOME/.config/spotify
        ${pkgs.spicetify-cli}/bin/spicetify backup apply
      '';
    };
  };
}
