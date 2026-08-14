# Maintenance

Everything below is a nushell def from `modules/hjem/nushell/config.nu` unless it says otherwise.

## Daily

```bash
nrt        # nh os test  -- build and activate, reverts on reboot
nrs        # nh os switch -- activate and make it the boot default
nrbt       # nh os boot  -- applies on next boot only
nrbld      # nh os build -- build without activating

tu         # tack update -- refresh every pin
tu nixpkgs # refresh one pin
tl         # tack look -- which pins have newer upstream

closure    # size of the current system closure
recycle    # keep the last 10 generations, then garbage-collect
```

`tu` and `tl` `cd` into the repo first, so they work from anywhere.

`nrs` does more than switch: on success it pushes the closure to the `anomalos` cachix cache and pins it as `current-system` with `--keep-revisions 3`. At the time of writing -- on a fork, that push fails and the switch itself is unaffected. I plan to decouple these.

## Something Broke

**Roll back to the previous generation:**

```bash
sudo nixos-rebuild switch --rollback
```

**Boot does not come up:** pick a previous generation from the boot menu. NixOS keeps 10 of them (`boot.loader.systemd-boot.configurationLimit`).

**The config broke everything:**

```bash
cd ~/repo/public/anomalos
jj log          # find the last commit that worked
jj edit <id>
nrs
```

**The YubiKey locked you out:** boot single-user mode, rename `modules/nixos-modules/security/yubikey.nix` to `_yubikey.nix`, rebuild.

**Recovering from a live image** is in [Installing](./install.md#recovery-from-a-live-image).

## Build Failures

```bash
sudo nix-collect-garbage -d && nrt

tu nixpkgs                    # refresh a pin after a hash mismatch
rm -rf ~/.cache/nix           # clear the eval cache
nh os test -- --show-trace    # verbose; nrt does not pass arguments through
```

`nix-build ci.nix` builds every host and returns nonzero on the first failure, which tells "my host broke" apart from "the repo broke". See [Testing](./testing.md).

## Desktop

**Hyprland will not start:**

```bash
cat /tmp/hypr/$(ls -t /tmp/hypr/ | head -1)/hyprland.log
echo $XDG_SESSION_TYPE     # should be "wayland"
```

**noctalia is missing:**

```bash
noct-r                              # restart it
journalctl --user -u noctalia
```

**Audio:**

```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```

## The Root Filled Up

`/` is a 256M tmpfs. When it fills, something is writing outside the persisted set.

```bash
show-tmpfs      # usage, then the largest files sitting on the root
```

Add the offending path to `modules/nixos-modules/persist.nix` and rebuild. See [ZFS and snapshots](./zfs.md#the-tmpfs-root).

## General

```bash
journalctl -xe
systemctl --failed
systemctl --user --failed
zpool status
```

## Updating Wrapped Packages

The `weegsware` packages built from upstream source are managed by [nvfetcher](https://github.com/berberman/nvfetcher):

```bash
cd ~/repo/public/anomalos
nvfetcher            # rewrites _sources/generated.nix
```

Config is `nvfetcher.toml`. The nixpkgs-override packages move when `nixpkgs` moves, so `tu nixpkgs` is what updates those.

## Redrawing the Diagrams

The two SVGs in the README are generated:

```bash
draw            # nu lib/scripts/draw.nu
```

## Help

[NixOS Discourse](https://discourse.nixos.org/) · [NixOS Wiki](https://nixos.wiki/) · [Issues](https://codeberg.org/weegs710/AnomalOS/issues)
