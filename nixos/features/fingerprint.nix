{ moduleWithSystem, ... }: {
  flake.nixosModules.fingerprint = moduleWithSystem (
    { ... }:
    { ... }: {
      services.fprintd.enable = true;

      persistance.directories = [
        "/var/lib/fprintd"
      ];
    }
  );
}