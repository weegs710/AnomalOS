# anomalOS - my gaming centric NixOS configuration

> **Important**: This is a hobbyist project. I'm learning as I go. If something's broken or stupid, that's why. This config is designed for my machine and my workflow. It might work on your system, it might not. There are no guarantees. You're welcome to use the whole thing or just steal bits and pieces. It's all FOSS, so do whatever you want with it.

> **Requirements**: nushell is required for this configuration. Shell wrapper scripts and utilities are written in nushell and will not work without it. nushell is included in the flake, but if you're cherry-picking modules, make sure you have it installed. You have been warned.

![anomalOS Overview](docs/assets/anomalOS-overview.svg)

![anomalOS Diagram](docs/assets/anomalOS-diagram.svg)

## features

<details>
<summary>Desktop</summary>

Hyprland with noctalia-shell for the bar, launcher, lock screen, and control center. Single config at `modules/hjem/hyprland.nix`.

**Workspaces:**
1. **comms** — endcord, gajim
2. **dev** — fresh, ghostty
3. **games** — steam
4. **media** — Euphonica, Stremio
5. **web** — Helium
- **stash** (special) — pavucontrol, nmtui, blueman, LACT, btop, piper, pulsemixer, cliphist

**Keybinds:**

| Key | Action |
|-----|--------|
| Super+1-5 | Switch workspace |
| Super+Shift+1-5 | Move window to workspace |
| Super+PageUp/Down | Cycle workspaces |
| Super+MouseWheel | Cycle workspaces |
| Super+grave | Toggle stash |
| Super+Shift+grave | Move window to stash |
| Super+Return | ghostty |
| Super+Space | superfile |
| Super+Escape | Close window |
| Super+F | Fullscreen |
| Super+G | Float toggle |
| Super+Backspace | Resize mode (arrows, Esc to exit) |
| Super+Arrows | Move focus |
| Super+Shift+Arrows | Move window |
| Super+Home/End | Volume up/down |
| Super+Pause | Mute |
| Super (tap) | wlr-which-key menu |
| Super+Tab | noctalia control center |
| Ctrl+Alt+L | Lock screen |
| Ctrl+Alt+Delete | Power menu |
| Print | Capture menu |

wlr-which-key is the primary navigation layer. Super tap opens it for app launches, screenshots, power menu. Full menu in `modules/hjem/wlr-which-key.nix`.

</details>

<details>
<summary>Security</summary>

- **YubiKey** — U2F for login, sudo, polkit. Auto-login on plug, auto-lock on unplug.
- **Firewall** — nftables. Drops everything by default. SSH on port 2222. Gaming ports 23243-23262 open for Divinity Original Sin 2.
- **Suricata** — network intrusion detection, logs to `/var/log/suricata/`
- **DNSCrypt** — encrypted DNS via dnscrypt-proxy, Cloudflare + Quad9, DNSSEC required
- **Kernel hardening** — ASLR, stack protection, kernel pointer hiding, SYN flood protection, ICMP rate limiting

</details>

<details>
<summary>Development</summary>

- **fresh** — TUI editor with LSP for nix, python, hyprlang, nushell. Full toolchain (nixd, alejandra, basedpyright, ruff, hyprls, nufmt, marksman) baked into the wrapper.
- **devshell** — `nix develop` drops into nushell with the same tools. See [Contributing](#contributing).
- **Claude Code** — AI-assisted dev, `cc` alias for project management
- **nix-search-tv** — `ns` for fzf-powered package search
- **nix-index** — command-not-found handler

</details>

<details>
<summary>Gaming</summary>

- **steam** — Proton, Protontricks, Gamescope, controller support, 32-bit compat
- **Decky Loader** — steam plugin system, web UI at localhost:8080
- **MangoHud** — performance overlay, 5 presets (0=off → 4=full), Shift+F12 to toggle
- **Emulators** — RetroArch (16 cores), PPSSPP, DeSmuME, Ryujinx, ProtonUp-Qt

</details>

<details>
<summary>Media</summary>

- **Audio** — Pipewire + WirePlumber, hardware mixing, Bluetooth (A2DP, HSP/HFP)
- **Music** — MPD + Euphonica GTK4 client. Beets for tagging with MusicBrainz. `scrapem` for playlists → MP3, `scrapev` for video.
- **Media creation** — GIMP 3, OBS Studio, Video2x
- **Streaming** — Stremio for video, Transmission for torrents

</details>

## ZFS setup

- `zroot` pool on NVMe — system, nix, home
- `zgames` pool on a separate drive — games (optional)
- Automated hourly/daily/weekly/monthly snapshots via sanoid
- Compression and auto-trim enabled

I use ZFS because I like the snapshot safety net. I inevitably break or delete things (I'm dumb), and having ZFS + jujutsu + NixOS generations means I can almost always undo it. See [ZFS Snapshots & Recovery](docs/BACKUP.md).

## getting started

> **Important**: This config is for my machine. Might work on yours, might not. No guarantees.

**Before you start:** x86_64, internet, sudo access, at least 100GB free. Your NixOS config needs the ZFS fileSystems declared before running install.sh or it won't boot.

```bash
git clone https://github.com/weegs710/AnomalOS.git ~/dotfiles
cd ~/dotfiles

# Read the comments in install.sh before you run this
./install.sh
```

`install.sh` handles partitioning (1GB boot, 16GB swap, rest ZFS), pool creation, and nixos-install. Full details in the comments inside install.sh. See `modules/nixos-modules/zfs.nix` for the dataset layout.

**Post-install YubiKey setup** (if enabled):

```bash
mkdir -p ~/.config/Yubico
pamu2fcfg > ~/.config/Yubico/u2f_keys

# Test it — should require a touch
sudo echo "YubiKey working!"
```

**Verify:**
- [ ] Desktop loads
- [ ] Network works
- [ ] Audio works (`systemctl --user status pipewire`)
- [ ] YubiKey requires touch (if enabled)

**After install, stop using raw nixos-rebuild:**

```bash
nrt    # Test changes (safe — reverts on reboot)
nrs    # Apply changes
```

**Recovery:** boot won't come up? Select a previous generation from the boot menu — NixOS keeps them for this exact reason.

<details>
<summary>USB recovery steps</summary>

```bash
sudo zpool import -f zroot
sudo mount -t zfs zroot/root /mnt
sudo mount /dev/nvme1n1p3 /mnt/boot  # adjust device name
sudo mount -t zfs zroot/nix /mnt/nix
sudo mount -t zfs zroot/persist /mnt/persist
sudo mount -t zfs zroot/cache /mnt/cache

sudo nixos-rebuild switch --flake /mnt/home/weegs/dotfiles#nixosConfigurations.HX99G
sudo reboot
```

</details>

## how it works

Everything is managed with flake-parts and hjem. Shareables (`modules/shareables/`) are wrapped packages with configs baked in, referenced via `inputs.self.packages`.

Because of the flake-parts setup, adding new modules is ezpz. Everything in `modules/` gets auto-imported — drop a file and it's in. Files prefixed with `_` are excluded from auto-import.

**System modules** (`modules/nixos-modules/`) — NixOS-level stuff. Services, packages, kernel, networking:

```nix
{ inputs, self, ... }:
{
  flake.nixosModules.my-new-thing = { config, lib, pkgs, ... }:
    with lib; {
      config = mkIf config.mySystem.features.whatever {
        # your config here
      };
    };
}
```

**User config modules** (`modules/hjem/`) — anything that goes in `~/.config` or `~/.local/share`:

```nix
{...}: {
  flake.nixosModules.my-app = { config, lib, pkgs, ... }: let
    username = config.mySystem.user.name;
  in with lib; {
    config = mkIf config.mySystem.features.whatever {
      hjem.users.${username}.xdg.config.files = {
        "my-app/config".text = ''
          # your config here
        '';
      };
    };
  };
}
```

**Feature toggles** live in `modules/hosts/hx99g.nix`. Set `gaming = false` and all gaming modules become no-ops. Toggle here, don't delete module files.

**Adding packages:** user packages go in `modules/nixos-modules/packages.nix`. System-wide packages go in the relevant module or directly in hx99g.nix.

New files need to be git-tracked before nix can see them — flakes only track git-tracked files.

## maintenance

```bash
nfu                                  # Update all flake inputs
nfu nixpkgs                          # Update a single input (nixpkgs is an example -- use any input name from flake.nix)
recycle                              # Keep last 10 generations, GC the rest
sudo nixos-rebuild switch --rollback # Rollback
```

Garbage collection and store optimization both run automatically.

**Config broke everything:**
```bash
cd ~/dotfiles
jj log        # Find the last working commit
jj edit <id>
nrs
```

**YubiKey locked you out:** boot single-user mode, set `mySystem.features.yubikey = false` in hx99g.nix, rebuild.

<details>
<summary>Troubleshooting</summary>

**Build failures:**
```bash
sudo nix-collect-garbage -d && nrt

nix flake update nixpkgs   # hash mismatch
rm -rf ~/.cache/nix         # clear eval cache
nrt -- --show-trace         # verbose output
```

**Hyprland won't start:**
```bash
cat /tmp/hypr/$(ls -t /tmp/hypr/ | head -1)/hyprland.log
echo $XDG_SESSION_TYPE  # should be "wayland"
```

**Noctalia missing:**
```bash
systemctl --user restart noctalia
journalctl --user -u noctalia
```

**Audio:**
```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```

**General:**
```bash
journalctl -xe
systemctl --failed
systemctl --user --failed
```

Help: [NixOS Discourse](https://discourse.nixos.org/) · [NixOS Wiki](https://nixos.wiki/) · [Issues](https://github.com/weegs710/AnomalOS/issues)

</details>

## contributing

Feel free to fork this and do whatever. If you find bugs or have improvements, pull requests are welcome -- just run `nix develop` first so we're using the same tools and formatter. The devshell has everything: nix LSP, alejandra, basedpyright, ruff, hyprls, nufmt, and nushell.

But remember, this is primarily my personal config, and I am still fairly new to this stuff.

## credits

**[Michael C Buckley](https://github.com/Michael-C-Buckley)**, **[iynaix](https://github.com/iynaix)**, **[vimjoyer](https://github.com/vimjoyer)** — for helping me figure out NixOS. Reading their configs and vimjoyer's videos are how I actually learned how to do any of this.

## license

MIT License. Do whatever you want with it.

## links

- GitHub: https://github.com/weegs710/AnomalOS
- Codeberg: https://codeberg.org/weegs710/AnomalOS
