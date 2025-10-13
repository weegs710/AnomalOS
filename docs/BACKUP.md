# Backup & Recovery Guide

## Overview

This system uses [Restic](https://restic.net/) for automated backups. Restic provides encrypted, deduplicated, and compressed backups with excellent performance.

**Key Features:**
- **Automated**: Runs daily via systemd timer
- **Encrypted**: All backups encrypted with password (managed via agenix)
- **Deduplicated**: Only stores changed data, saving space
- **Retention Policy**: Keeps 7 daily, 5 weekly, 12 monthly snapshots

## Backup Configuration

### What's Being Backed Up

**Included:**
- `/home/weegs` - All user files and configurations
- `/etc/nixos` - System configuration (if exists, though we use ~/dotfiles)

**Excluded:**
- `/home/weegs/.cache` - Temporary cache files
- `/home/weegs/.local/share/Steam` - Large game files (re-downloadable)
- `/home/weegs/Downloads` - Temporary downloads

### Storage Location

- **Repository**: `/backup/restic-repo`
- **Password**: Encrypted in `secrets/restic-password.age`, decrypted to `/run/agenix/restic-password`

### Schedule

- **Frequency**: Daily at midnight
- **Persistent**: Yes (runs on next boot if system was off)
- **Service**: `restic-backups-localbackup.service`
- **Timer**: `restic-backups-localbackup.timer`

## Manual Backup Operations

### Trigger Backup Manually

```bash
# Run backup now
sudo systemctl start restic-backups-localbackup.service

# Watch backup progress
sudo journalctl -u restic-backups-localbackup.service -f
```

### Check Backup Status

```bash
# View timer status
systemctl status restic-backups-localbackup.timer

# View last backup log
sudo journalctl -u restic-backups-localbackup.service -n 50

# List all snapshots
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password snapshots
```

### Verify Backup Integrity

```bash
# Check repository integrity
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password check

# Check with data verification (slower but thorough)
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password check --read-data
```

## Restoring Files

### List Available Snapshots

```bash
# Show all snapshots
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password snapshots

# Show specific snapshot contents
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password ls <snapshot-id>
```

### Restore Specific Files

```bash
# Restore single file to original location
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password restore <snapshot-id> \
  --target / --include /home/weegs/important-file.txt

# Restore to different location (safer)
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password restore <snapshot-id> \
  --target /tmp/restore --include /home/weegs/important-file.txt
```

### Restore Entire Directory

```bash
# Restore entire home directory to /tmp/restore
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password restore latest \
  --target /tmp/restore --include /home/weegs

# After verification, move files back
cp -a /tmp/restore/home/weegs/some-dir ~/some-dir
```

### Interactive File Browser

```bash
# Mount backup as filesystem for easy browsing
sudo mkdir -p /mnt/restic-backup
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password mount /mnt/restic-backup

# Browse in another terminal
ls /mnt/restic-backup/snapshots/

# Unmount when done (Ctrl+C in mount terminal or)
sudo umount /mnt/restic-backup
```

## Full System Recovery

### Scenario: Complete System Rebuild

If you need to rebuild the system from scratch:

**1. Install NixOS**
```bash
# Follow standard NixOS installation
# Don't worry about configuration yet
```

**2. Restore Dotfiles**
```bash
# Clone your dotfiles repo
git clone <your-dotfiles-repo> ~/dotfiles
cd ~/dotfiles

# Copy hardware configuration
sudo cp /etc/nixos/hardware-configuration.nix ~/dotfiles/hardware-configuration.nix
```

**3. Restore Secrets**

Your encrypted secrets are in the repo, but you'll need your YubiKey to decrypt them:

```bash
# Secrets are already in repo (secrets/*.age)
# They'll automatically decrypt on boot if your YubiKey is configured
```

**4. Build System**
```bash
cd ~/dotfiles
sudo nixos-rebuild switch --flake .#Rig
```

**5. Restore User Files from Backup**

```bash
# Mount backup drive/repository
# (assumes /backup/restic-repo is accessible)

# Restore specific important files
sudo restic -r /backup/restic-repo restore latest \
  --target /tmp/restore --include /home/weegs

# Review and copy back
cp -a /tmp/restore/home/weegs/Documents ~/
cp -a /tmp/restore/home/weegs/Pictures ~/
# etc.
```

### Scenario: Recover Specific Configuration

```bash
# Restore specific config files
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password restore latest \
  --target /tmp/restore --include /home/weegs/.config/some-app

# Compare with current
diff -r /tmp/restore/home/weegs/.config/some-app ~/.config/some-app

# Copy back if needed
cp -a /tmp/restore/home/weegs/.config/some-app ~/.config/
```

## Maintenance

### Prune Old Snapshots

This happens automatically during each backup, but you can run manually:

```bash
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password forget \
  --keep-daily 7 \
  --keep-weekly 5 \
  --keep-monthly 12 \
  --prune
```

### Check Repository Statistics

```bash
# Show repository stats
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password stats

# Show stats for specific snapshot
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password stats <snapshot-id>
```

### Cleanup Unused Data

```bash
# Remove unreferenced data (run after prune)
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password prune
```

## Off-Site Backup Strategy

**Current Setup**: Local backups to `/backup/restic-repo`

**Recommended Additions:**

### Option 1: External Drive

```nix
# Add to configuration.nix
services.restic.backups.external = {
  inherit (config.services.restic.backups.localbackup)
    paths exclude passwordFile pruneOpts;
  initialize = true;
  repository = "/mnt/external-drive/restic-repo";
  timerConfig = {
    OnCalendar = "weekly";
    Persistent = true;
  };
};
```

### Option 2: Cloud Storage (S3/B2/etc)

```nix
# Add to configuration.nix
services.restic.backups.cloud = {
  inherit (config.services.restic.backups.localbackup)
    paths exclude passwordFile pruneOpts;
  initialize = true;
  repository = "s3:s3.amazonaws.com/your-bucket/restic-repo";
  environmentFile = config.age.secrets.restic-s3-credentials.path;
  timerConfig = {
    OnCalendar = "daily";
    Persistent = true;
  };
};
```

### Option 3: Remote Server (SSH)

```nix
# Add to configuration.nix
services.restic.backups.remote = {
  inherit (config.services.restic.backups.localbackup)
    paths exclude passwordFile pruneOpts;
  initialize = true;
  repository = "sftp:user@remote-server.com:/backup/restic-repo";
  timerConfig = {
    OnCalendar = "daily";
    Persistent = true;
  };
};
```

## Troubleshooting

### Backup Service Failing

```bash
# Check service status
systemctl status restic-backups-localbackup.service

# View full logs
sudo journalctl -u restic-backups-localbackup.service -xe

# Common issues:
# - Repository locked: Another backup running or crashed
#   Solution: sudo restic -r /backup/restic-repo unlock
# - Permission issues: Check /backup directory ownership
# - Password file missing: Verify agenix secret is decrypted
```

### Repository Locked

```bash
# If backup crashed, repository might be locked
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password unlock
```

### Cannot Access Password File

```bash
# Verify agenix decrypted the secret
ls -la /run/agenix/restic-password

# Check agenix service
systemctl status agenix.service

# Manually decrypt (for testing)
cd ~/dotfiles
agenix -d secrets/restic-password.age
```

### Repository Corruption

```bash
# Check and repair
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password check
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password rebuild-index
```

## Best Practices

1. **Regular Verification**: Run `restic check` monthly to verify integrity
2. **Test Restores**: Periodically restore a few files to verify backups work
3. **Off-Site Copies**: Maintain at least one off-site backup
4. **Monitor Space**: Check backup repository size doesn't exceed available storage
5. **Document Recovery**: Keep this guide accessible outside the system (printed or separate device)
6. **Protect Secrets**: Never commit unencrypted password; always use agenix
7. **Review Excludes**: Periodically review exclusion list to ensure you're not missing important data

## Quick Reference

```bash
# Backup now
sudo systemctl start restic-backups-localbackup.service

# List snapshots
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password snapshots

# Restore latest
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password restore latest --target /tmp/restore

# Check integrity
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password check

# View stats
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password stats
```

## Related Documentation

- [SECRETS.md](SECRETS.md) - Password management with agenix
- [INSTALLATION.md](INSTALLATION.md) - System installation and setup
- [Restic Documentation](https://restic.readthedocs.io/) - Official Restic docs
