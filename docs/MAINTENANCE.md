# Maintenance

Routine upkeep for keeping things running.

## Updates

### Quick update (use this)

```bash
rig-up    # Updates flake inputs, tests, prompts to switch
```

### Manual if you need more control

```bash
cd ~/dotfiles
nix flake update           # Update all inputs
nrt-rig                    # Test
nrs-rig                    # Apply if good
```

### Update a single input

```bash
nix flake lock --update-input nixpkgs
```

## Garbage collection

Runs automatically daily — removes generations older than 90 days. If the boot menu gets bloated:

```bash
recycle    # Keep last 10 generations, GC everything else
```

Manual options:
```bash
sudo nix-collect-garbage -d                       # Nuke everything except current
sudo nix-collect-garbage --delete-older-than 14d  # Custom age
df -h /nix                                        # Check how much space you freed
```

## Health checks

```bash
systemctl --failed              # Any broken services?
sudo journalctl -xe             # Recent logs
df -h                           # Disk space
du -sh /nix/store               # Nix store size
```

## Rolling back

```bash
sudo nixos-rebuild switch --rollback

# Or just reboot — test configs revert automatically

# List generations:
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

You can also select a previous generation from the boot menu at startup.

## Security maintenance

```bash
# Check for security advisories at:
# https://nixos.org/manual/nixos/stable/index.html#sec-security-updates

# Update immediately for security patches:
nix flake lock --update-input nixpkgs
nrs-rig
```

YubiKey:
```bash
# Re-register if needed:
pamu2fcfg > ~/.config/Yubico/u2f_keys

# Check services:
sudo systemctl status yubikey-autologin-init
```

## Store optimization

```bash
sudo nix-store --optimize    # Deduplicates files in store
```

Already running automatically — `nix.optimise.automatic = true` runs daily at midnight via systemd timer (configured in nix-daemon.nix).

## Monthly checklist

- [ ] `rig-up` — update system
- [ ] `df -h` — check disk space
- [ ] `systemctl --failed` — any broken services?
- [ ] Test a ZFS snapshot restore (see [Backups](BACKUP.md))
- [ ] Check security advisories
- [ ] Commit and push any dotfiles changes

## Emergency

### System won't boot

Select previous generation from boot menu. If that doesn't work, see the USB recovery steps in [Installation](INSTALLATION.md).

### Config broke everything

```bash
cd ~/dotfiles
jj log              # Find the last working commit
jj edit <id>        # Switch working copy to that commit
nrs-rig
```

### Lost access (YubiKey issues)

Boot into single-user mode, set `mySystem.features.yubikey = false` in rig.nix, rebuild.
