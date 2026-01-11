# ZFS Snapshots & Recovery Guide

## Overview

This system uses ZFS with automated snapshots via [sanoid](https://github.com/jimsalterjrs/sanoid) for data protection. Snapshots are copy-on-write pointers that initially reference existing data and only consume additional space as data changes.

**Key Features:**
- **Automated**: Runs hourly via systemd timer
- **Copy-on-write**: Snapshots share unchanged data with original
- **Multi-tier retention**: Hourly, daily, weekly, and monthly retention policies
- **Automatic pruning**: Old snapshots are automatically removed based on retention policy

## Snapshot Configuration

### Datasets and Retention Policies

**Critical datasets (zroot/persist):**
- 50 hourly snapshots
- 15 daily snapshots
- 3 weekly snapshots
- 1 monthly snapshot

**Important datasets (zroot/root):**
- 24 hourly snapshots
- 7 daily snapshots
- 2 weekly snapshots
- 1 monthly snapshot

**Games datasets (zgames/games):**
- 12 hourly snapshots
- 7 daily snapshots
- 1 weekly snapshot
- 0 monthly snapshots

**Standard datasets (zroot/nix):**
- 12 hourly snapshots
- 3 daily snapshots
- 1 weekly snapshot

### Snapshot Naming

Snapshots are automatically named by sanoid:
```
zroot/persist@autosnap_2025-12-11_16:00:00_hourly
zroot/persist@autosnap_2025-12-11_00:00:00_daily
zgames/games@autosnap_2025-12-08_00:00:00_weekly
```

## Managing Snapshots

### List All Snapshots

```bash
# List all snapshots across all datasets
zfs list -t snapshot

# List snapshots for specific dataset
zfs list -t snapshot -r zroot/persist

# Show snapshot space usage
zfs list -t snapshot -o name,used,refer
```

### View Sanoid Service Status

```bash
# Check sanoid service status
systemctl status sanoid.service

# Check sanoid timer
systemctl status sanoid.timer

# View sanoid logs
sudo journalctl -u sanoid.service -f
```

### Trigger Manual Snapshot

```bash
# Sanoid runs hourly, but you can trigger manually
sudo systemctl start sanoid.service

# Or create a manual snapshot directly
sudo zfs snapshot zroot/persist@manual-$(date +%Y%m%d-%H%M%S)
```

## Restoring Data

### Browse Snapshot Contents

Every ZFS dataset has a `.zfs/snapshot` directory containing all snapshots:

```bash
# Browse persistent data snapshots
cd /persist/.zfs/snapshot
ls -la

# List specific snapshot
ls -la autosnap_2025-12-11_16:00:00_hourly/

# Browse game storage snapshots
cd /mnt/games/.zfs/snapshot
ls -la
```

### Restore Individual File

```bash
# Copy file from snapshot to current location
cp /persist/.zfs/snapshot/autosnap_2025-12-11_16:00:00_hourly/path/to/file ~/path/to/file

# Restore game save file
cp /mnt/games/.zfs/snapshot/autosnap_2025-12-11_12:00:00_hourly/SteamLibrary/userdata/12345/saves/save.dat \
   /mnt/games/SteamLibrary/userdata/12345/saves/save.dat
```

### Restore Entire Directory

```bash
# Restore directory to temporary location for review
cp -a /persist/.zfs/snapshot/autosnap_2025-12-11_12:00:00_hourly/home/weegs/Documents /tmp/restored-docs

# After verification, move back
mv /tmp/restored-docs ~/Documents
```

### Rollback Entire Dataset

**WARNING**: This destroys all changes made after the snapshot.

```bash
# List snapshots to find the one you want
zfs list -t snapshot -r zroot/persist

# Rollback to specific snapshot (destroys newer snapshots)
sudo zfs rollback zroot/persist@autosnap_2025-12-11_12:00:00_hourly

# Rollback to most recent snapshot
sudo zfs rollback zroot/persist@autosnap_2025-12-11_16:00:00_hourly
```

### Clone Snapshot for Testing

Create a writable clone to test changes before committing:

```bash
# Clone snapshot to new dataset
sudo zfs clone zroot/persist@autosnap_2025-12-11_12:00:00_hourly zroot/persist-test

# Mount and test
sudo zfs set mountpoint=/mnt/test zroot/persist-test

# If satisfied, promote clone and delete original
# Otherwise, delete clone
sudo zfs destroy zroot/persist-test
```

## System Recovery

### Recover from Boot Failure

If system becomes unbootable after configuration change:

1. **Boot from older NixOS generation** (shown in boot menu)
2. **System automatically boots from last working state**
3. **No ZFS action needed** - NixOS generations handle boot recovery

### Recover Deleted Files

```bash
# Find when file was last present
zfs list -t snapshot -r zroot/persist | grep hourly

# Browse snapshots until you find the file
ls /persist/.zfs/snapshot/autosnap_2025-12-11_14:00:00_hourly/path/to/deleted-file

# Restore it
cp /persist/.zfs/snapshot/autosnap_2025-12-11_14:00:00_hourly/path/to/deleted-file ~/restored-file
```

### Disaster Recovery

If the system drive fails completely:

1. **Reinstall NixOS on new drive**
2. **Clone AnomalOS repository** from GitHub/Codeberg
3. **Rebuild system** with `sudo nixos-rebuild switch --flake .#Rig`
4. **Your configuration is preserved** in git

**Important**: ZFS snapshots are local to the drives. For true disaster recovery, maintain:
- Configuration in git (GitHub/Codeberg)
- Critical personal data in external backup (external drive, cloud storage)
- ZFS snapshots protect against accidental deletion and corruption, not hardware failure

## Maintenance

### Check Snapshot Space Usage

```bash
# See how much space snapshots are using
zfs list -o space

# Check specific dataset
zfs list -o name,used,avail,refer,usedsnap,usedds zroot/persist
```

### Manual Snapshot Cleanup

Sanoid automatically prunes old snapshots, but you can manually delete if needed:

```bash
# Delete specific snapshot
sudo zfs destroy zroot/persist@autosnap_2025-12-01_12:00:00_hourly

# Delete range of snapshots (careful!)
sudo zfs destroy zroot/persist@autosnap_2025-12-01_00:00:00_hourly%autosnap_2025-12-05_00:00:00_hourly
```

### Modify Retention Policy

Edit `/home/weegs/dotfiles/modules/system/core/zfs-snapshots.nix`:

```nix
templates.critical = {
  hourly = 50;   # Increase/decrease retention
  daily = 15;
  weekly = 3;
  monthly = 1;
  autoprune = true;
  autosnap = true;
};
```

After changes:
```bash
sudo nixos-rebuild switch --flake .#Rig
```

## Snapshot Space Efficiency

### How Snapshots Use Space

1. **Initial snapshot**: Nearly zero space (just metadata)
2. **As files change**: Only changed blocks consume space
3. **As files are deleted**: Space cannot be reclaimed until snapshot is pruned

### Example Space Usage

```bash
# Check snapshot overhead
zfs list -o name,used,avail,refer,usedsnap,usedds

# Output example:
# NAME            USED  AVAIL   REFER  USEDSNAP  USEDDS
# zroot/persist   45G   800G    42G    3.2G      42G
#
# Interpretation:
# - Total space used: 45GB
# - Actual dataset: 42GB
# - Snapshot overhead: 3.2GB (changed/deleted data in snapshots)
```

### When Snapshots Use Significant Space

- **Heavy file churn**: Editing large files frequently
- **Large deletions**: Deleting data that snapshots still reference
- **Long retention**: Keeping snapshots of rapidly changing data

For gaming datasets, snapshots can grow if you:
- Delete and reinstall large games often
- Modify many save files

## Best Practices

1. **Regular verification**: Occasionally restore a file from snapshot to verify snapshots work
2. **Monitor space**: Check `zfs list -o space` monthly to ensure snapshot overhead is reasonable
3. **Understand limitations**: ZFS snapshots are not off-site backups - they protect against accidental deletion, not hardware failure
4. **Git for configuration**: Your NixOS configuration in git is your primary system backup
5. **External backup for irreplaceable data**: Photos, documents, personal projects should have additional backup
6. **Test rollbacks**: Practice rolling back a non-critical dataset to understand the process

## Troubleshooting

### Snapshots Not Being Created

```bash
# Check sanoid timer is active
systemctl status sanoid.timer

# Check sanoid service logs
sudo journalctl -u sanoid.service -n 50

# Manually trigger sanoid
sudo systemctl start sanoid.service
```

### Out of Space

```bash
# Check what's using space
zfs list -o space

# If snapshots are using too much space, reduce retention
# Edit modules/system/core/zfs-snapshots.nix and rebuild
```

### Cannot Delete Snapshot

```bash
# Check if snapshot has dependent clones
zfs list -t all | grep <snapshot-name>

# Destroy clones first, then snapshot
```

## Quick Reference

```bash
# List all snapshots
zfs list -t snapshot

# Browse snapshot contents
cd /persist/.zfs/snapshot
ls -la

# Restore file from snapshot
cp /persist/.zfs/snapshot/<snapshot-name>/path/to/file ~/restored-file

# Check space usage
zfs list -o space

# View sanoid status
systemctl status sanoid.service

# Trigger manual snapshot
sudo systemctl start sanoid.service

# Rollback dataset (DESTRUCTIVE)
sudo zfs rollback zroot/persist@<snapshot-name>
```

## Related Documentation

- [INSTALLATION.md](INSTALLATION.md) - ZFS pool setup during installation
- [FEATURES.md](FEATURES.md) - ZFS filesystem features
- [Sanoid Documentation](https://github.com/jimsalterjrs/sanoid) - Official sanoid docs
- [OpenZFS Documentation](https://openzfs.github.io/openzfs-docs/) - ZFS reference documentation
