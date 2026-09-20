# NixOS Migration Plan: Alpha (AMD Desktop) → Omega (ThinkPad T14)

## Goal
- Current AMD desktop → **Alpha** (keeps running normally)
- New ThinkPad T14 → **Omega** (fresh install with disko, full 512GB SSD, impermanence)

## Host Structure

| System | Hostname | Config | Drivers | Boot | Disko | Impermanence |
|--------|----------|--------|---------|------|-------|--------------|
| AMD Desktop | Alpha | `nixos/hosts/Alpha/` | AMD (amdgpu) | systemd-boot | No | No |
| ThinkPad T14 | Omega | `nixos/hosts/Omega/` | Intel (i915, vaapi) | systemd-boot | Yes (LUKS + btrfs) | Yes (tmpfs root) |

## Files Created

### `nixos/hosts/Alpha/configuration.nix`
- `hostName = "Alpha"`
- Imports: `base`, `general`, `desktop`, `quickshell`, `pipewire`, `powersave`, `gaming`, `hostAlpha-hardware`
- Boot: `linuxPackages_latest`, systemd-boot, 5 config limit, NTFS
- CPU/GPU: `hardware.cpu.amd.updateMicrocode`, `hardware.graphics` (enable + 32-bit), Bluetooth enabled
- Display: SDDM (Wayland) + Hyprland via uwsm (`defaultSession = "hyprland-uwsm"`)
- Swap: zram (zstd)
- No disko, no impermanence

### `nixos/hosts/Alpha/hardware-configuration.nix`
- AMD hardware config (kvm-amd, ext4 root, vfat `/boot`)

### `nixos/hosts/Omega/disko.nix`
- Full-disk partitioning using disko
- **LUKS encryption**
- **btrfs** filesystem with LVM
- **16G swap partition** with resume support
- GPT layout:
  - BIOS boot (1M, EF02)
  - ESP (1G, vfat, type EF00) → `/boot`
  - swap (16G)
  - LUKS (100% remaining) → LVM `btrfs_vg` → btrfs subvolumes: `/root`, `/persist`, `/nix`
- Root (`/`) is **tmpfs** (`size=25%`, `mode=755`)

### `nixos/hosts/Omega/hardware-configuration.nix`
- Intel/T14 kernel modules (kvm-intel, i915, iwlwifi, thinkpad_acpi, nvme)
- No filesystems or LUKS declarations — disko handles these

### `nixos/hosts/Omega/configuration.nix`
- `hostName = "Omega"`
- Imports: `base`, `general`, `desktop`, `pipewire`, `gaming`, `quickshell`, `powersave`, `hostOmega-hardware`, `impermanence`, plus disko modules
- Intel GPU: `intel-media-driver`, `intel-vaapi-driver`
- No zram, no Bluetooth

### `nixos/base/persistance.nix`
- Defines `persistance.*` options (enable, nukeRoot, volumeGroup, directories, files, data, cache)

### `nixos/base/user.nix`
- Defines `preferences.user.name` (default: `jeremyl`)

### `nixos/extra/impermanence.nix`
- Wraps `nix-community/impermanence` with `persistance.*` options
- Root nuke script: renames old `/root` btrfs subvol, creates fresh one, GCs backups older than 30 days
- System persistence: `/var/log`, `/var/lib/bluetooth`, `/var/lib/nixos`, `/etc/NetworkManager`, `/var/lib/libvirt`, `/tmp`, `/etc/machine-id`

### `nixos/extra/hjem.nix`
- Wraps hjem for declarative user home dirs; `clobberByDefault = true`

### `nixos/features/impermanence.nix`
- Convenience module: enables persistence with user from preferences

### `nixos/features/general.nix`
- User account, nix flakes, comma (nix-index-database), direnv, shell packages
- Persistence declarations for `.ssh`, `.config/nvim`, `my-nixos-dotfiles`, `.mozilla`, `.cache/wallust`, `.cache/matugen`, etc.

### `nixos/features/desktop.nix`
- Meta-module: hyprland + kitty + theming + virtualization + desktop-packages + dotfiles + neovim + vscodium

### `nixos/features/hyprland.nix`
- Hyprland compositor, xwayland, polkit, dbus

### `nixos/features/pipewire.nix`
- PipeWire audio (rtkit, ALSA, PulseAudio compat)

### `nixos/features/powersave.nix`
- thermald, powertop, power-profiles-daemon

### `nixos/features/gaming.nix`
- Steam, Proton-GE, gamemode, nix-gaming cache

### `nixos/features/virtualization.nix`
- libvirtd, qemu, swtpm, virt-manager, spice, looking-glass

### `nixos/features/theming.nix`
- Cursors, fonts, icons, GTK/Qt, wallust, matugen, waybar, rofi, hyprlock, etc.

### `nixos/features/kitty.nix`
- Kitty terminal config module (imported by `desktop`)

### `nixos/features/hyprglass.nix`
- Hyprglass package (Hyprland plugin, perSystem)

### `wrappedPrograms/`
- `zsh.nix` — Zsh with baked-in `.zshrc`
- `environment.nix` — Zsh + all interactive tools on PATH
- `git.nix` — Git with hardcoded author identity
- `nh.nix` — `nh` with `NH_FLAKE` pointing to `~/my-nixos-dotfiles`
- `quickshell.nix` — QuickShell with zoxide
- `dotfiles.nix` — Symlink activation script for `~/.config/*` → repo configs
- `cli-tools.nix` — kitty, htop, btop, wget, zoxide, ripgrep, fzf, bat, eza, fd, lazygit, tmux
- `desktop-apps.nix` — Zen Browser, Discord, Vesktop, Spotify, Obsidian, OBS, Thunar, Nautilus, etc.
- `desktop-utils.nix` — brightnessctl, ffmpeg, pulsemixer, playerctl, bluez, ntfs3g, etc.
- `dev.nix` — gcc, python3, nodejs, opencode, LSPs (nil, nixd, pyright, ts_ls, clangd, hyprls)
- `desktop_programs.nix` — Meta-module: dev + cli-tools + desktop-apps + desktop-utils
- `neovim.nix` — Neovim via hjem, sets EDITOR
- `vscodium.nix` — VSCodium + marketplace extensions

## Installation on T14

```bash
# 1. Boot from NixOS minimal ISO
sudo -i

# 2. Connect to WiFi (iwctl is NOT on the minimal ISO — use wpa_cli)
sudo wpa_cli
#   interactive:
#   scan
#   scan_results
#   add_network
#   set_network 0 ssid "YOUR_WIFI_SSID"
#   set_network 0 psk "YOUR_PASSWORD"
#   set_network 0 key_mgmt WPA-PSK
#   enable_network 0
#   save_config
#   quit
# (graphical ISO alternative: nmtui)

# 2b. Enable flakes for nix commands
export NIX_CONFIG="experimental-features = nix-command flakes"

# 3. Identify disk
lsblk

# 4. Set LUKS passphrase (use /root — /tmp can be read-only on the live ISO)
echo -n "your-secure-passphrase" > /root/secret.key
chmod 600 /root/secret.key

# 5. Clone dotfiles
nix-env -iA nixos.git 2>/dev/null || true
git clone https://github.com/G7Shadow/my-nixos-dotfiles /mnt/dotfiles

# 6. Edit disk device ID in disko.nix and point the passphrase at /root
DISK=$(ls /dev/disk/by-id/nvme-* | head -1)
sed -i "s|/dev/disk/by-id/nvme-INSERT_YOUR_SSD_ID_HERE|$DISK|" \
  /mnt/dotfiles/nixos/hosts/Omega/disko.nix
sed -i 's|/tmp/secret.key|/root/secret.key|' \
  /mnt/dotfiles/nixos/hosts/Omega/disko.nix

# 7. Partition, encrypt, format, mount (flake ref — disko.nix defines
#    flake.diskoConfigurations.diskoOmega, not a plain disko config).
#    NOTE: this remounts /mnt, hiding the clone underneath.
nix run github:nix-community/disko -- --flake /mnt/dotfiles#diskoOmega \
  --mode destroy,format,mount

# 7b. Re-clone and re-apply the edits from step 6 (the old clone is hidden)
git clone https://github.com/G7Shadow/my-nixos-dotfiles /mnt/dotfiles
DISK=$(ls /dev/disk/by-id/nvme-* | head -1)
sed -i "s|/dev/disk/by-id/nvme-INSERT_YOUR_SSD_ID_HERE|$DISK|" \
  /mnt/dotfiles/nixos/hosts/Omega/disko.nix
sed -i 's|/tmp/secret.key|/root/secret.key|' \
  /mnt/dotfiles/nixos/hosts/Omega/disko.nix

# 8. Generate hardware config (written to /mnt/etc/nixos/). Do NOT overwrite
#    the repo file — nixos/hosts/Omega/hardware-configuration.nix is a flake
#    module defining `flake.nixosModules.hostOmega-hardware`, which
#    configuration.nix imports. Since flake.nix auto-imports every .nix file
#    as a flake module, dropping the raw generated output there breaks eval.
nixos-generate-config --no-filesystems --root /mnt

# 9. Merge only the kernel-module lines (boot.initrd.availableKernelModules,
#    boot.kernelModules) from /mnt/etc/nixos/hardware-configuration.nix into
#    /mnt/dotfiles/nixos/hosts/Omega/hardware-configuration.nix, keeping its
#    `flake.nixosModules.hostOmega-hardware` wrapper intact.

# 10. Install
nixos-install --flake /mnt/dotfiles#Omega

# 11. Reboot
reboot
```

## Post-Install (Optional)

### TPM Auto-Unlock
```bash
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p4
```

## Verification Checklist

- [ ] `hostname` returns "Alpha" on desktop, "Omega" on T14
- [ ] `nixos-rebuild switch` works on Alpha (current system)
- [ ] T14 boots and decrypts LUKS
- [ ] WiFi, sound, brightness, lid suspend work on T14
- [ ] T14: `nixos-rebuild switch --flake ~/my-nixos-dotfiles#Omega` works
- [ ] Omega: persistence survives reboot (`~/.ssh`, `~/my-nixos-dotfiles`, etc.)
- [ ] Omega: old root backups are GC'd after 30 days
- [ ] Wallust + matugen theming works on both
- [ ] All symlinks in `~/.config/` resolve correctly
