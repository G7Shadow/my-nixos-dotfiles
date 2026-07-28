{ moduleWithSystem, ... }: {
  flake.nixosModules.kitty = moduleWithSystem (
    { ... }:
    { pkgs, config, ... }:
    let
      user = config.preferences.user.name;
    in
    {
      hjem.users."${user}".packages = with pkgs; [ kitty ];
    }
  );
}
