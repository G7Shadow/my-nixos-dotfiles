{ config, ... }:
{
  flake.nixosModules.kitty =
    { pkgs, ... }:
    let
      user = config.preferences.user.name;
    in
    {
      hjem.users."${user}".packages = with pkgs; [ kitty ];
    };
}
