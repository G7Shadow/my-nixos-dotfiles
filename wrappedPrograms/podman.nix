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
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
    in
    {
      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };

      virtualisation.containers.containersConf.settings.engine = {
        compose_providers = [ "${pkgs.podman-compose}/bin/podman-compose" ];
        compose_warning_logs = false;
      };

      virtualisation.containers.registries.settings = {
        unqualified-search-registries = [
          "docker.io"
          "quay.io"
        ];
        registry = [
          { location = "docker.io"; }
          { location = "quay.io"; }
        ];
      };

      hjem.users."${user}".packages = [ self'.packages.podman ];

      persistance.data.directories = [ ".local/share/containers" ];
    }
  );
}
