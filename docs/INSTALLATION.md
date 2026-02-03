# Installation

> **Important**: This config is for my machine. Might work on yours, might not. No guarantees.

## Before you start

- x86_64 machine with internet
- sudo access
- At least 100GB free
- Your NixOS config needs the ZFS fileSystems declared before running install.sh or it won't boot

## Fresh install

```bash
git clone https://github.com/weegs710/AnomalOS.git ~/dotfiles
cd ~/dotfiles

# Read the comments in install.sh before you run this
./install.sh
```

`install.sh` handles partitioning (1GB boot, 16GB swap, rest ZFS), pool creation, and nixos-install. It assumes your config already has the ZFS fileSystems declared — see `modules/nixos-modules/zfs.nix` for the dataset layout. Full details are in the comments inside install.sh.

## Post-install

### YubiKey

If you enabled yubikey:

```bash
mkdir -p ~/.config/Yubico
pamu2fcfg > ~/.config/Yubico/u2f_keys

# Test it — should require a touch
sudo echo "YubiKey working!"
```

### Verify

- [ ] Desktop loads (Hyprland + Noctalia shell)
- [ ] Network works
- [ ] Audio works (`systemctl --user status pipewire`)
- [ ] Keyboard/mouse work
- [ ] YubiKey requires touch (if enabled)
- [ ] `nh` is available

### Daily drivers

After the first install, stop using raw nixos-rebuild:

```bash
nrt-rig    # Test changes
nrs-rig    # Apply changes
rig-up     # Update + test + prompt to switch
```

## Recovery

Boot won't come up? Select a previous generation from the boot menu — NixOS keeps them around for this exact reason.

Need to boot from USB and fix things:

```bash
sudo zpool import -f zroot
sudo mount -t zfs zroot/root /mnt
sudo mount /dev/nvme1n1p3 /mnt/boot  # adjust device name
sudo mount -t zfs zroot/nix /mnt/nix
sudo mount -t zfs zroot/persist /mnt/persist
sudo mount -t zfs zroot/cache /mnt/cache

sudo nixos-rebuild switch --flake /mnt/home/weegs/dotfiles#nixosConfigurations.Rig
sudo reboot
```

## What's next

- [Configuration](CONFIGURATION.md) — how everything's wired up
- [Features](FEATURES.md) — what's actually running
- [Troubleshooting](TROUBLESHOOTING.md) — when stuff breaks
