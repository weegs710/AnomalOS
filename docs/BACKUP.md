# ZFS Snapshots & Recovery

Automated snapshots via [sanoid](https://github.com/jimsalterjrs/sanoid). Snapshots are copy-on-write — they start at nearly zero space and only grow as data changes.

## Retention policies

Configured in `modules/nixos-modules/zfs.nix`:

| Dataset | Template | Hourly | Daily | Weekly | Monthly |
|---------|----------|--------|-------|--------|---------|
| zroot/persist | critical | 50 | 15 | 3 | 1 |
| zroot/root | important | 24 | 7 | 2 | 1 |
| zroot/nix | standard | 12 | 3 | 1 | — |

Old snapshots are pruned automatically based on these policies.

## List snapshots

```bash
zfs list -t snapshot                          # All snapshots
zfs list -t snapshot -r zroot/persist         # Specific dataset
zfs list -t snapshot -o name,used,refer       # With space usage
```

## Restore a file

Every dataset has a `.zfs/snapshot` directory:

```bash
# Browse what's available
ls /persist/.zfs/snapshot/

# Copy a file back
cp /persist/.zfs/snapshot/autosnap_2025-12-11_16:00:00_hourly/path/to/file ~/restored-file
```

## Restore a directory

```bash
cp -a /persist/.zfs/snapshot/autosnap_2025-12-11_12:00:00_hourly/path/to/dir /tmp/restored-dir
# Verify it looks right, then move it where you want
```

## Rollback entire dataset

**This destroys everything after the snapshot. Be sure.**

```bash
sudo zfs rollback zroot/persist@autosnap_2025-12-11_12:00:00_hourly
```

## Manual snapshot

```bash
sudo zfs snapshot zroot/persist@manual-$(date +%Y%m%d-%H%M%S)

# Or just kick sanoid:
sudo systemctl start sanoid.service
```

## Check snapshot space

```bash
zfs list -o name,used,avail,refer,usedsnap,usedds
# usedsnap = how much your snapshots are actually using
```

Snapshots eat space fast if you're deleting a lot or keeping long retention on datasets that change constantly.

## Sanoid health

```bash
systemctl status sanoid.service
systemctl status sanoid.timer
sudo journalctl -u sanoid.service -f
```

## What snapshots don't protect against

ZFS snapshots are local to the drive. They protect against accidental deletion and corruption — not hardware failure. For that:
- Your config is in git (GitHub/Codeberg) — that's your system backup
- Critical personal data (photos, documents, projects) needs an external backup too

## Troubleshooting

**Snapshots not being created:**
```bash
systemctl status sanoid.timer        # Is it running?
sudo journalctl -u sanoid.service -n 50
sudo systemctl start sanoid.service  # Kick it manually
```

**Out of space:**
```bash
zfs list -o space    # See what's eating it
# Reduce retention in modules/nixos-modules/zfs.nix and rebuild
```

**Can't delete a snapshot:**
```bash
# Probably has dependent clones
zfs list -t all | grep <snapshot-name>
# Destroy the clones first
```
