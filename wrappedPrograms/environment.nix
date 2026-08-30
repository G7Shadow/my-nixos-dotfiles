{ inputs, lib, ... }: {
  perSystem =
    { pkgs, self', ... }:
    let
      starshipToml = pkgs.writeText "starship.toml" ''
        command_timeout = 500
        scan_timeout = 100
      '';
    in
    {
      packages.environment = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = self'.packages.zsh;
        runtimeInputs = with pkgs; [
          zoxide
          fzf
          starship
          direnv
          eza
          bat
          nitch
        ];
        env = {
          STARSHIP_CONFIG = "${starshipToml}";
        };
      };
    };
}
