# Features

What is configured, and which tag gates it. Anything without a tag is on for every host.

## Desktop -- `desktop`

Hyprland, with [noctalia](https://github.com/noctalia-dev/noctalia) for the bar, launcher, lock screen and control center. Login is `ly` on tty, defaulting into the Hyprland session.

The Hyprland config is Lua, not `hyprland.conf`. `modules/user-level/desktop/hyprland/hyprland.nix` places `hyprland.lua` at `~/.config/hypr/hyprland.lua`. Three nushell helpers -- `hypr-focus`, `hypr-pin-toggle`, `hypr-split-toggle` -- exist because the right behaviour depends on which layout the workspace is using.

### Workspaces

All five are persistent, each with its own layout.

| #   | Name  | Layout                        | Holds                              |
| --- | ----- | ----------------------------- | ---------------------------------- |
| 1   | COMMS | dwindle                       | vesktop, Steam chat, gajim         |
| 2   | DEV   | scrolling                     | zed                                |
| 3   | WEB   | master                        | helium                             |
| 4   | GAMES | monocle, no gaps, no rounding | steam, gamescope, ES-DE, Median XL |
| 5   | MEDIA | monocle                       | mpv, Jellyfin                      |

`stash` is a special workspace for things you summon and dismiss: pavucontrol, pulsemixer, nmtui, blueman, btop and cliphist.

### Keybinds

`Super` is the mod.

| Key                                | Action                                                                 |
| ---------------------------------- | ---------------------------------------------------------------------- |
| `Super` (tap, on release)          | wlr-which-key menu                                                     |
| `Super+1` to `Super+5`             | switch workspace                                                       |
| `Super+Shift+1` to `Super+Shift+5` | move window to workspace                                               |
| `Super+PageUp` / `PageDown`        | cycle workspaces                                                       |
| `Super+MouseWheel`                 | cycle workspaces                                                       |
| `Super+grave`                      | toggle the stash                                                       |
| `Super+Shift+grave`                | move window to the stash                                               |
| `Super+Space`                      | yazi, floating                                                         |
| `Super+Escape`                     | close window                                                           |
| `Super+F`                          | fullscreen                                                             |
| `Super+G`                          | toggle floating                                                        |
| `Super+P`                          | pseudo                                                                 |
| `Super+O`                          | toggle split, layout-aware                                             |
| `Super+\`                          | pin, floats first if tiled                                             |
| `Super+Arrows`                     | move focus -- cycles the stack in monocle, walks the tape in scrolling |
| `Super+Shift+Arrows`               | move window                                                            |
| `Super+Backspace`                  | resize submap; arrows resize, `Esc` or `Enter` exits                   |
| `Super+LMB` / `RMB`                | drag / resize window                                                   |
| `Super+Tab`                        | noctalia control center                                                |
| `Print`                            | capture menu                                                           |
| `Ctrl+Alt+Delete`                  | power menu                                                             |

wlr-which-key is the primary navigation layer. Tapping `Super` opens it, and it is where app launches, system tools, service control, screenshots and the power menu live. The menu is in `modules/user-level/desktop/wlr-which-key/wlr-which-key.nix`, with submenus for comms, games, media, tools, audio, notifications, wireless, services and capture.

## Security

| Thing    | Detail                                                                                                                                              |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| YubiKey  | `pam_u2f` on login, sudo, `ly` and polkit. Touch required on every auth                                                                             |
| Firewall | nftables, default deny, ping blocked. `virbr0`, `virbr-k8s`, `tailscale0` and `lo` trusted                                                          |
| Suricata | inline IPS in NFQ mode -- it drops packets, not just alerts. Logs to `/var/log/suricata/`                                                           |
| DNSCrypt | `dnscrypt-proxy`, Cloudflare + Quad9, DNSSEC required, no-log servers required, IPv6 queries blocked. `systemd-resolved` and `unbound` are both off |
| Secrets  | agenix, identity is the SSH host key on `/persist`. See [Secrets](./secrets.md)                                                                     |

Open ports:

| Port                             | For                      |
| -------------------------------- | ------------------------ |
| 2222/tcp                         | SSH                      |
| 8080/tcp                         | Decky Loader web UI      |
| 8096/tcp                         | Jellyfin (`server`)      |
| 51413/tcp+udp                    | Transmission (`server`)  |
| 23243-23262/tcp, 23243+23253/udp | Divinity: Original Sin 2 |
| 4000/tcp                         | Median XL Sigma LAN host |
| 1337/tcp                         |                          |

Kernel hardening, in `modules/system-level/boot.nix`: full ASLR (`randomize_va_space=2`), kernel pointers hidden (`kptr_restrict=2`), `dmesg` restricted to root, ptrace limited to descendants (`yama.ptrace_scope=1`), core dumps piped to `/bin/false` with `suid_dumpable=0`, SYN cookies, RFC1337 TIME_WAIT protection, ICMP redirects rejected in both directions, reverse-path filtering, and forwarding off on both IP versions. BBR congestion control with the `fq` qdisc is a throughput choice rather than a hardening one.

Boot is `systemd-boot`, keeping 10 generations.

## Development -- `dev`

- zed, the primary editor. It resolves language servers off `PATH`, so `nixd` comes from its own module and the css/html/ts servers come from this bundle. Config in `modules/user-level/desktop/zed/`.
- devshell: `nix-shell devshell.nix`, or `cd` in and let direnv load it. Drops into the wrapped nushell with nixd, nil, nixfmt, nufmt, basedpyright, ruff, hyprls, marksman, biome, dprint, clippy, rust-analyzer, rustfmt, typescript-language-server, vscode-langservers-extracted, nvfetcher and git.
- toolchains: rust (cargo, rustc, clippy, rustfmt, rust-analyzer), python (python3, uv, ruff), node (nodejs, typescript).
- Claude Code, `ccl` launches `claude-launcher` which picks a project first.
- nix-search-tv, `ns` for fzf-driven package search.
- nix-index + nix-index-database, the command-not-found handler on a pre-built community database.
- [nix-shop](https://codeberg.org/weegs710/nix-shop), `shop`, for running any version of any package without installing it. Wired in `modules/system-level/shop.nix`.
- wireshark, tmux, direnv with `nix-direnv`, gh, hyperfine, jq, ripgrep.

## Gaming -- `gaming`

- steam, the `weegsware` wrapped build, with Proton, gamescope, controller support and 32-bit compat.
- heroic for Epic/GOG, globally wired through gamescope at 2560x1440 @ 144, wayland backend.
- Decky Loader, Steam plugin system, web UI on `localhost:8080`. It is a passthru of the wrapped steam package rather than a separate input.
- MangoHud, with five presets in `presets.conf` from off to a full GPU/CPU/VRAM/frametime readout.
- gamemode, nix-ld, ntsync, protontricks, ProtonUp-Qt, OpenRA.
- ES-DE with RetroArch carrying 36 libretro cores, plus MAME with a flattened `crt-geom` shader chain. Per-core `.opt` files are declarative, in `modules/user-level/gaming/es-de/opts/`.
- Native ports and recomps, each with its own module and declarative config: [Dusklight](https://github.com/TwilitRealm/dusklight) (Twilight Princess), [2Ship2Harkinian](https://github.com/HarbourMasters/2ship2harkinian) (Majora's Mask), [zelda3](https://github.com/snesrev/zelda3) (A Link to the Past), Dinosaur Planet, AM2R, DCSS, Median XL via `d2launcher`, and Godot.

The whole `modules/user-level/gaming/` subtree is gated by one `only.imports` line in its `bundle.nix`.

## Media

Audio is Pipewire + WirePlumber with rtkit, ALSA/pulse/JACK bridges, 32-bit ALSA support, and a resampler at quality 10 pinned to 44.1/48kHz. Bluetooth carries LDAC, AAC, aptX HD, aptX and SBC-XQ, with hardware volume on and mSBC off.

Music is MPD with the rmpc TUI. Three nushell tools sit alongside it: `snag` (playlist to MP3), `yoink` (video downloads) and `sync-music` (ADB sync to Android).

Media creation: GIMP 3 with plugins, Inkscape, `gpu-screen-recorder` with a replay buffer, mpv, zathura, qview.

### Media Server -- `server`

`modules/system-level/media-server/` is gated as a subtree:

- Jellyfin with VAAPI hardware decode, on 8096. `/mnt/media/music` is a read-only bind of `~/Music` off `/persist`, because a 700 home directory blocks it otherwise.
- The arr suite: Radarr, Sonarr, Prowlarr, Bazarr, FlareSolverr, Recyclarr on a weekly schedule. All `openFirewall = false`; they are reachable over Tailscale, not the LAN.
- Transmission as a system service with the tremc TUI, RPC bound to localhost only.
- Navidrome, listening on all interfaces so it is reachable over Tailscale.
- media-churn, which deletes watched content 14 days after its last play, unmonitors it in Radarr/Sonarr, exempts anything tagged `keep`, and resets the clock when something gets rewatched.

SearXNG is also `server`-gated, on 8888, fronted by `tailscale serve` over HTTPS.

## Lab -- `lab`

`modules/system-level/k8s.nix` and `k8s-HA.nix`, behind the `mySystem.k8sLab` option tree. This is the only place outside `options.nix` that defines `mySystem` options.

## Everywhere

Untagged, because they are true of every machine:

- Tailscale, with its auth key from agenix, and its interface trusted by the firewall
- SSH on 2222
- the firewall, DNSCrypt, Suricata, YubiKey
- preservation and the tmpfs root, see [ZFS and snapshots](./zfs.md)
- sanoid snapshots
- nushell as the shell, with the whole def library
- the Nix substituters -- `anomalos.cachix.org`, `noctalia.cachix.org`, `attic.xuyh0120.win/lantian` and `cache.nixos.org` -- declared fleet-wide in `core.nix` so a new host gets them without being told
- automatic GC daily at 90 days, store optimisation nightly, and a 5GB/15GB `min-free`/`max-free` band
