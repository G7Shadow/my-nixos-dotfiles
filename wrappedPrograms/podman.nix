{ inputs, moduleWithSystem, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.podman = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.podman;
        runtimeInputs = [ pkgs.podman-compose ];
      };
    };

  flake.nixosModules.podman = moduleWithSystem (
    { self', ... }:
    { config, ... }:
    let
      user = config.preferences.user.name;
    in
    {
      virtualisation.podman = {
        enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };

      hjem.users."${user}".packages = [ self'.packages.podman ];
    }
  );
}
