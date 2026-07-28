{ moduleWithSystem, ... }: {
  flake.nixosModules.quickshell = moduleWithSystem (
    { self', ... }:
    { config, ... }:
    let
      user = config.preferences.user.name;
    in
    {
      hjem.users."${user}".packages = [
        self'.packages.quickshellWrapped
      ];
    }
  );
}
