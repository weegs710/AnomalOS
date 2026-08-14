# Installing

`install.sh` works in two stages. First it builds a plan: which host, which disk each storage pool goes on, and how large the boot and swap partitions are. It checks that plan against what the host's configuration declares, and refuses to go on if the two disagree. Only then does it write to a disk.

Nothing is written until every check has passed and you have confirmed once.

> **Important**: This config is built for my machine. It might work on yours, it might not.

## Before You Start

**Hardware.** x86_64 with AVX2, BMI2 and XSAVE (`x86_64-v3`, so most CPUs from 2013 onward but not all). The hardware config is AMD-only. On Intel, change `boot.zfs.devNodes` from `"/dev/disk/by-partuuid"` to `"/dev/disk/by-id"` in `modules/hosts/<HOST>/hardware.nix` and drop the AMD microcode and `amdgpu` lines. You want an internet connection and at least 100GB free.

**A host directory.** The installer only offers hosts that exist. Create `modules/hosts/<NAME>/` with a `metadata.nix` in it first, see [Architecture](./architecture.md#hosts-are-directories). Set `mySystem.user.name` in that host's `host.nix` too -- it is the account you will be logging into.

**A hostId.** `metadata.nix` needs 8 lowercase hex characters, different on every machine, because ZFS reads it from `/etc/hostid` to refuse importing a pool that belongs to another host:

```bash
head -c4 /dev/urandom | od -A none -t x4
```

**The live image.** Boot the NixOS installer ISO. It carries every tool the script needs: `nix`, `lsblk`, `jq`, `sgdisk`, `zpool`, `zfs`, `mkfs.fat`, `mkswap`, `blkdiscard`, `nixos-install` and `nixos-generate-config`. If any are missing the script says which and stops.

## Running It

```bash
git clone https://codeberg.org/weegs710/AnomalOS.git ~/anomalos
cd ~/anomalos

./install.sh --save-plan /tmp/plan
```

That asks the questions, runs every check, writes the plan to `/tmp/plan` and exits without touching a disk. Read it, then:

```bash
./install.sh --plan /tmp/plan
```

`./install.sh` with no arguments does both in one pass: asks, shows the plan, and waits for one confirmation before erasing anything.

## Options

```
--plan FILE        Use a previously saved plan instead of asking questions.
--save-plan FILE   Build and check a plan, write it to FILE, then stop
                   without touching any disk.
--regenerate       Rewrite the host's hardware.nix from the disks this run
                   creates. Only meaningful for a host that already has one.
--keep-hardware    Leave an existing hardware.nix untouched.
--yes              Do not ask for the final confirmation. Intended for
                   automated runs; it still refuses a plan that fails checks.
--no-install       Partition the disks, create the filesystems and mount
                   them, then stop without building or installing anything.
-h, --help         Show this message.
```

## What It Asks

1. **Which host.** It lists every directory under `modules/hosts/` with its system and tags, read out of `metadata.nix`.
2. **Which disk holds each pool.** The pools come from the host's configuration -- `zroot` and `zgames` for HX99G. One disk per pool; a disk can hold only one. Disks that already carry a ZFS pool are flagged with the pool's name and a warning that choosing it destroys everything on it.
3. **Which disk to boot from.** Only asked when there is more than one pool. Defaults to the disk holding the first pool.
4. **How much swap.** Default 16GiB, used during installation only. What the machine swaps to afterwards is whatever its configuration declares, which on HX99G is zram at 25% of RAM.
5. **Encryption.** If yes, each pool is created with `aes-256-gcm` and a passphrase prompt. You also want `boot.zfs.requestEncryptionCredentials = true` in the host's config.
6. **Whether to restore `/persist`.** See below.

The boot partition is always 1GiB and is not asked about.

## What It Checks

The plan is checked against `lib/requirements.nix`, which reads the host's evaluated `fileSystems` and reports the pools, datasets, mount points, boot label, `hostId`, substituters and trusted keys the configuration demands.

| Check                                          | Failure                                                                |
| ---------------------------------------------- | ---------------------------------------------------------------------- |
| every pool the config needs has a disk         | names the unassigned pools                                             |
| every dataset the config mounts is in the plan | names them, and says the machine would fail to mount them after reboot |
| the boot label matches                         | names both labels, and says the machine would not boot                 |
| the host has a `hostId`                        | points at `metadata.nix`                                               |
| every disk in the plan is a real block device  | names the path                                                         |

Any failure stops the run and prints how many problems were found. Nothing has been written at that point.

## What It Does

1. **Partitions the boot disk.** `blkdiscard`, `sgdisk --zap-all`, then a 1GiB `EF00` boot partition, a swap partition, and the rest as `BF01`. Partition paths are resolved by asking the kernel, since some device families insert a `p` before the number.
2. **Wipes every other pool disk** entirely and gives it one `BF01` partition.
3. **Creates the pools** with `ashift=12`, `autotrim=on`, `compression=zstd`, `acltype=posixacl`, `atime=off`, `xattr=sa`, `normalization=formD` and `mountpoint=none`.
4. **Creates and mounts the datasets** the configuration declares, shallow-first so a deeper mount is never buried under a later one. All `mountpoint=legacy`; NixOS does the mounting.
5. **Runs `nixos-generate-config`** and either writes `hardware.nix` for a brand-new host or asks before replacing an existing one. The previous version is kept at `hardware.nix.replaced`.
6. **Re-reads the configuration** now that the disks exist and re-runs every check, plus a bootability check that the config declares both `/` and `/boot`. A fresh host's plan is otherwise validated against a config that describes no disks at all.
7. **Installs**:

```bash
nixos-install --root /mnt \
  --file ./assemble.nix --attr "nixosConfigurations.$HOST" \
  --no-root-password --no-channel-copy \
  --option substituters "..." --option trusted-public-keys "..."
```

`--file`/`--attr` makes `nixos-install` build with `--store /mnt`, so the build lands on the disks that were just prepared rather than in the installer's RAM. A `nix-build` here instead runs the live image out of memory. The substituters and keys are read out of the host's own configuration, so packages that only exist in a private cache are fetched rather than compiled from source.

## Restoring `/persist`

Before the datasets are created, the installer offers to restore `/persist` from a `zfs send` stream instead of creating it empty.

`/persist` holds the SSH host key at `/persist/etc/ssh/ssh_host_ed25519_key`, and that key is the agenix identity. Restore it and the machine's existing secrets keep decrypting. Create it empty and the machine generates a new host key, and every secret has to be re-encrypted before it works again, see [Secrets](./secrets.md).

```bash
# on the old machine, or from a backup
zfs send zroot/persist@some-snapshot > /run/media/usb/persist.zfs
```

Then answer yes and give the full path when the installer asks.

## After the First Boot

**Set up the YubiKey**, if you have one. The module is always loaded; without one, rename `modules/nixos-modules/security/yubikey.nix` to `_yubikey.nix` and rebuild.

```bash
# persist this directory BEFORE creating the key file -- /home is on a tmpfs root.
# add ~/.config/Yubico to the preservation user directories first.
mkdir -p ~/.config/Yubico
pamu2fcfg > ~/.config/Yubico/u2f_keys

sudo echo "YubiKey working"   # should require a touch
```

**Check it came up:** the desktop loads, the network works, `systemctl --user status pipewire`, the YubiKey requires a touch if enabled, and `systemctl --failed` is empty.

**Stop using raw `nixos-rebuild`:**

```bash
nrt   # build and activate, reverts on reboot
nrs   # build, activate, and make it the boot default
```

`nrs` also pushes the system closure to my cachix cache after switching. You do not have write access to it, so that step fails on a fork and the rebuild itself is unaffected.

A boot failure after the first successful generation is a boot-menu problem. NixOS keeps the previous generations for exactly this.

## Recovery From a Live Image

```bash
sudo zpool import -f zroot
sudo mount -t zfs zroot/root /mnt
sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
sudo mount -t zfs zroot/nix /mnt/nix
sudo mount -t zfs zroot/persist /mnt/persist
sudo mount -t zfs zroot/cache /mnt/cache

sudo nixos-enter --root /mnt

nh os switch --file /home/YOUR_USER/anomalos/assemble.nix nixosConfigurations.YOUR_HOST
exit

sudo reboot
```

`nh` takes `--file` and an attribute path here, not a flake reference.

## Testing It Without a Machine

Every path above is exercised in a throwaway VM by `lib/vmtest/`, including a real install followed by a reboot from disk. See [Testing](./testing.md).
