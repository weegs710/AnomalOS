# ZFS and Snapshots

ZFS is here for the snapshot safety net. Between ZFS, Jujutsu and NixOS generations, almost anything I break is undoable.

## Layout

| Mount                     | Device                       | Type                              |
| ------------------------- | ---------------------------- | --------------------------------- |
| `/`                       | tmpfs, 256M                  | wiped every boot                  |
| `/boot`                   | `/dev/disk/by-label/NIXBOOT` | vfat, 1GiB                        |
| `/tmp`                    | tmpfs, 5G                    |                                   |
| `/nix`                    | `zroot/nix`                  | zfs, needed for boot              |
| `/persist`                | `zroot/persist`              | zfs, needed for boot              |
| `/cache`                  | `zroot/cache`                | zfs, needed for boot              |
| `/mnt/games/1g1r`         | `zgames/games/roms`          | zfs                               |
| `/mnt/games/SteamLibrary` | `zgames/games/steam`         | zfs                               |
| `/mnt/games/heroic`       | `zgames/games/heroic`        | zfs                               |
| `/mnt/media`              | `zgames/media`               | zfs, `server` tag only            |
| `/mnt/media/music`        | `/persist/home/<user>/Music` | read-only bind, `server` tag only |

Pools are created with `ashift=12`, `autotrim=on`, `compression=zstd`, `acltype=posixacl`, `atime=off`, `xattr=sa` and `normalization=formD`. Every dataset is `mountpoint=legacy`; NixOS does the mounting.

There is no swap partition after the install. `zramSwap` takes over at 25% of RAM with zstd.

The declarations live in `modules/hosts/HX99G/hardware.nix`, except `/` which `modules/system-level/persist.nix` overrides with `lib.mkForce`, and the media mounts which come from the `server`-gated `modules/system-level/media-server/`.

## The Tmpfs Root

`/` is a 256M tmpfs and it is wiped on every reboot. It is small on purpose: if you forget to persist something, you hit an out-of-space error immediately instead of silently losing the file on the next boot.

`/persist` is where things that matter live. `/cache` is for things you would rather not redownload but will not miss. Everything else is rebuilt from the Nix store at boot.

Persistence is [nix-community/preservation](https://github.com/nix-community/preservation), pure systemd tmpfiles and mounts.

`show-tmpfs` prints current root usage and the largest files sitting on it.

## Snapshots

Automated by [sanoid](https://github.com/jimsalterjrs/sanoid) on an hourly timer. Snapshots are copy-on-write: they start at nearly zero and only grow as the data underneath changes.

Templates are in `modules/system-level/sanoid.nix`. Dataset assignments are in `modules/hosts/HX99G/zfs.nix`.

| Dataset             | Policy                                                        |
| ------------------- | ------------------------------------------------------------- |
| `zroot/persist`     | `desktop` template -- hourly 12, daily 7, weekly 2, monthly 1 |
| `zgames/games/roms` | hourly 6, daily 3, weekly 1                                   |

Both autoprune and autosnap. Nothing else is snapshotted: `/nix` and `/cache` are reproducible, and the game libraries are re-downloadable.

**List them:**

```bash
zfs list -t snapshot                     # all
zfs list -t snapshot -r zroot/persist    # one dataset
zfs list -t snapshot -o name,used,refer  # with space usage
```

**Restore a file.** Every dataset carries a `.zfs/snapshot` directory:

```bash
ls /persist/.zfs/snapshot/
cp /persist/.zfs/snapshot/autosnap_2026-08-15_16:00:00_hourly/path/to/file ~/restored-file
```

**Restore a directory:**

```bash
cp -a /persist/.zfs/snapshot/autosnap_2026-08-15_12:00:00_hourly/path/to/dir /tmp/restored-dir
```

**Roll back an entire dataset.** This destroys everything written after the snapshot:

```bash
sudo zfs rollback zroot/persist@autosnap_2026-08-15_12:00:00_hourly
```

**Take one by hand:**

```bash
sudo zfs snapshot zroot/persist@manual-$(date +%Y%m%d-%H%M%S)
sudo systemctl start sanoid.service        # or just kick sanoid
```

## Health

```bash
zpool status
zfs list -o name,used,avail,refer,usedsnap,usedds   # usedsnap = what snapshots actually cost
systemctl status sanoid.service sanoid.timer
sudo journalctl -u sanoid.service -f
```

**Snapshots are not being created:**

```bash
systemctl status sanoid.timer
sudo journalctl -u sanoid.service -n 50
sudo systemctl start sanoid.service
```

**Out of space:**

```bash
zfs list -o space
```

Then reduce retention in `modules/system-level/sanoid.nix` and rebuild.

**A snapshot will not delete**, usually because something is cloned from it:

```bash
zfs list -t all | grep <snapshot-name>
```

Destroy the clones first.

## What This Does Not Cover

Snapshots are local to the drive. They protect against deleting the wrong thing and against corruption, not against the drive dying.

The config is in git on Codeberg, and that is the system backup. Anything personal needs a real external backup on top of this.

`/persist` also carries the SSH host key that agenix secrets are encrypted to, which is what makes a reinstall survivable. See [Installing](./install.md#restoring-persist) and [Secrets](./secrets.md).
