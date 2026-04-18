{ self, ... }:
{
  flake.nixosModules.profile-server = {
    imports = with self.nixosModules; [
      drivers-intel # or amd, whatever the server has
    ];
  };
}
