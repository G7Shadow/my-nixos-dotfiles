{ self, ... }:
{
  flake.homeModules.noctalia =
    { pkgs, inputs, ... }:
    {
      imports = [ inputs.noctalia.homeModules.default ];

      programs.noctalia-shell = {
        enable = true;
      };
    };
}
