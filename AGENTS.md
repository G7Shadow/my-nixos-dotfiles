# AGENTS.md

## Repo

NixOS flake (flake-parts) for two hosts:

- `Alpha`: AMD desktop, ext4, no disko/impermanence.
- `Omega`: ThinkPad T14, disko LUKS/btrfs, tmpfs root, impermanence.

Omega is the current daily driver. Installation details live in `PLAN.md`.

## Commands

- Switch current host: `nh os switch` (the wrapped `nh` sets `NH_FLAKE=$HOME/my-nixos-dotfiles`).
- Target the other host: `nh os switch ~/my-nixos-dotfiles#Alpha` or `#Omega`.
- Build without switching: `nh os build` or `nix build .#nixosConfigurations.Omega.config.system.build.toplevel --no-link`.
- Check evaluation only: `nix eval .#nixosConfigurations.Omega.config.system.build.toplevel.drvPath`.
- `nh os switch` needs interactive sudo here; do not expect it to run unattended.
- No test suite, lint, formatter, or CI is configured. Validate by evaluating/building the target host.

## Critical rules

- `flake.nix` auto-imports every `.nix` file as a flake-parts module, except `flake.nix` and files prefixed with `_`. Every file must define `flake.*` (for example `flake.nixosModules.foo`). Never drop a plain NixOS module or raw `hardware-configuration.nix` into the tree.
- Add a host by defining both `flake.nixosConfigurations.<Host>` and `flake.nixosModules.host<Host>` in `nixos/hosts/<Host>/configuration.nix`.
- Use `config.preferences.user.name` instead of hardcoding `jeremyl`.
- User packages and home files belong under `hjem.users."${config.preferences.user.name}"`.
- Access flake packages from NixOS modules via `moduleWithSystem` and `self'.packages.*`; see `nixos/features/quickshell.nix`.
- `wrappedPrograms/` contains `perSystem` wrappers and matching `flake.nixosModules.*`; `desktop_programs.nix` is the meta-module.
- Most `nixos/features/*` changes affect both hosts. Put host-specific behavior in `nixos/hosts/<Host>/configuration.nix`.
- Edit `nixos/features/config/*`, not `~/.config/*`: `wrappedPrograms/dotfiles.nix` symlinks config dirs into `~/.config`. Runtime-written files such as Quickshell `config.json` and Vesktop `quickCss.css` will appear dirty.
- Omega-only: impermanence/disko. Do not add `persistance` or disko imports to Alpha.
- `nixos/hosts/Omega/disko.nix` contains the real disk by-id and `/tmp/secret.key`; installation rewrites the key path. Read `PLAN.md` before touching it.
- `hyprglass` is pinned to a Hyprland-ABI-compatible version in `nixos/features/hyprglass.nix`; update `version`/`rev`/`hash` together and keep `nativeBuildInputs = [ pkgs.wayland-scanner ]`.
- The Quickshell README is upstream/Arch-oriented; this repo uses `pkgs.quickshell` wrapped in `wrappedPrograms/quickshell.nix`. Structural QML changes need `qs kill`/restart, not just hot reload.
- Vesktop uses system Vencord via `(vesktop.override { withSystemVencord = true; })` in `wrappedPrograms/desktop-apps.nix`; do not add a separate Vencord package.

## Validation

- Prefer targeted builds first. A full system build after a nixpkgs bump can download multiple GiB and take over 30 minutes.
- For a full build without hogging resources: `nix build .#nixosConfigurations.Omega.config.system.build.toplevel --no-link --max-jobs 1 --cores 2`.
- `nix flake update` rewrites `flake.lock` and can trigger large rebuilds. Do not update nixpkgs just to fix one package.
