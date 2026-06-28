# NixOS Migration Plan: Alpha (AMD Desktop) → Omega (ThinkPad T14)

## Goal
- Current AMD desktop → **Alpha** (keeps running normally)
- New ThinkPad T14 → **Omega** (fresh install with disko, full 512GB SSD)

## Host Structure

| System | Hostname | Config | Drivers | Boot | Disko |
|--------|----------|--------|---------|------|-------|
| AMD Desktop | Alpha | `hosts/Alpha/` | AMD (via laptop.nix) | systemd-boot | No |
| ThinkPad T14 | Omega | `hosts/Omega/` | Intel (explicit) | systemd-boot | Yes |

## Files Created

### `modules/nixos/hosts/Alpha/configuration.nix`
- Copy of original Omega config (pre-changes)
- `hostName = "Alpha"`
- Uses `profile-laptop` (which imports `drivers-amd`)
- No disko imports — uses existing ext4 partitions

### `modules/nixos/hosts/Alpha/hardware-configuration.nix`
- Original AMD hardware config (kvm-amd, ext4 filesystems, etc.)

### `modules/nixos/hosts/Omega/disko.nix`
- Full-disk partitioning using disko
- **LUKS encryption**
- **ext4** filesystem
- **16G swap partition** + zramSwap (both active)
- GPT layout:
  - ESP (1G, vfat, type EF00) → `/boot`
  - swap (16G)
  - LUKS (100% remaining) → `/dev/mapper/crypted` → ext4 → `/`

## Files Modified

### `modules/nixos/hosts/Omega/hardware-configuration.nix`
- Intel/T14 kernel modules (kvm-intel, i915, iwlwifi, thinkpad_acpi, nvme)
- No filesystems or LUKS declarations — disko handles these

### `modules/nixos/hosts/Omega/configuration.nix`
- `profile-laptop` replaced with individual modules:
  - `audio`, `hyprland`, `auto-cpufreq`, `virtualization`, `drivers-intel`
- Added disko imports:
  - `inputs.disko.nixosModules.disko`
  - `self.diskoConfigurations.diskoOmega`

### `modules/nixos/system/profiles/laptop.nix`
- Reverted to `drivers-amd` (used by Alpha)
- Omega now imports `drivers-intel` directly instead

## Installation on T14

```bash
# 1. Boot from NixOS minimal ISO
sudo -i

# 2. Identify disk
lsblk

# 3. Set LUKS passphrase
echo -n "your-secure-passphrase" > /tmp/secret.key

# 4. Clone dotfiles
git clone https://github.com/you/my-nixos-dotfiles /mnt/dotfiles

# 5. Edit disk device ID in disko.nix
nano /mnt/dotfiles/modules/nixos/hosts/Omega/disko.nix

# 6. Partition, encrypt, format, mount
nix run github:nix-community/disko -- --mode disko \
  /mnt/dotfiles/modules/nixos/hosts/Omega/disko.nix

# 7. Generate hardware config
nixos-generate-config --root /mnt

# 8. Copy generated hardware config to dotfiles
cp /mnt/etc/nixos/hardware-configuration.nix \
  /mnt/dotfiles/modules/nixos/hosts/Omega/hardware-configuration.nix

# 9. Install
nixos-install --flake /mnt/dotfiles#Omega

# 10. Reboot
reboot
```

## Post-Install (Optional)

### TPM Auto-Unlock
```bash
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p3
```

## Verification Checklist

- [ ] `hostname` returns "Alpha" on desktop, "Omega" on T14
- [ ] `nixos-rebuild switch` works on Alpha (current system)
- [ ] T14 boots and decrypts LUKS
- [ ] WiFi, sound, brightness, lid suspend work on T14
- [ ] T14: `nixos-rebuild switch --flake ~/my-nixos-dotfiles#Omega` works
