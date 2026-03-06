# Features

What's actually running. All features are gated by toggles in `modules/hosts/rig.nix` — see [Configuration](CONFIGURATION.md) for how to flip them.

## Security

### YubiKey (`yubikey.nix`)

U2F authentication for login, sudo, and polkit. Auto-login when YubiKey is plugged in, auto-lock when removed.

Setup:
```bash
mkdir -p ~/.config/Yubico
pamu2fcfg > ~/.config/Yubico/u2f_keys

# Add more keys:
pamu2fcfg -n >> ~/.config/Yubico/u2f_keys
```

Check status:
```bash
sudo journalctl -u yubikey-autologin-init
sudo journalctl -u yubikey-autologin-monitor
```

### Firewall (`firewall.nix`)

nftables. Drops everything by default. SSH on port 2222. Gaming ports 23243-23262 open for Divinity Original Sin 2.

```bash
sudo nft list ruleset    # See the rules
sudo ss -tulpn           # See listening ports
```

### Suricata (`suricata.nix`)

Network intrusion detection. Runs in the background, logs to `/var/log/suricata/`.

```bash
sudo systemctl status suricata
sudo tail -f /var/log/suricata/fast.log      # Alerts
sudo tail -f /var/log/suricata/eve.json      # Full logs
```

### DNSCrypt (`dnscrypt.nix`)

Encrypted DNS via dnscrypt-proxy. Dual upstream: Cloudflare + Quad9. DNSSEC required, aggressive caching.

```bash
sudo systemctl status dnscrypt-proxy
sudo journalctl -u dnscrypt-proxy
```

### Kernel hardening (`boot.nix` / `services.nix`)

ASLR, stack protection, kernel pointer hiding, SYN flood protection, ICMP rate limiting. SSH hardened in services.nix.

## Desktop

### Hyprland (`modules/hjem/hyprland.nix`)

Single config file deployed via Hjem. Dwindle tiling, VRR enabled.

**Workspaces:**
1. **comms** — endcord, gajim
2. **dev** — Zed, Ghostty terminals, fresh
3. **games** — Steam and games
4. **media** — Euphonica, Stremio
5. **web** — Helium browser
- **stash** (special) — utility apps (pavucontrol, nmtui, blueman, LACT, btop, piper, pulsemixer, cliphist)

**Keybinds:**

| Key | Action |
|-----|--------|
| Super+1-5 | Switch workspace |
| Super+Shift+1-5 | Move window to workspace |
| Super+PageUp/Down | Cycle workspaces |
| Super+MouseWheel | Cycle workspaces |
| Super+grave | Toggle stash workspace |
| Super+Shift+grave | Move window to stash |
| Super+Return | Terminal (Ghostty) |
| Super+Space | File manager (Superfile) |
| Super+Escape | Close window |
| Super+F | Fullscreen |
| Super+G | Float toggle |
| Super+Backspace | Resize mode (arrows, Esc to exit) |
| Super+Arrows | Move focus |
| Super+Shift+Arrows | Move window |
| Super+Home/End | Volume up/down |
| Super+Pause | Mute toggle |
| Super (tap) | wlr-which-key menu |
| Super+Tab | Noctalia control center |
| Ctrl+Alt+L | Lock screen |
| Ctrl+Alt+Delete | wlr-which-key power menu |
| Print | wlr-which-key capture menu |

**wlr-which-key** is the primary navigation layer — Super tap opens it. From there: quick app launches, screenshot/record, power menu. See `modules/hjem/wlr-which-key.nix` for the full menu structure.

**Auto-launch at login:** noctalia-shell only. All other apps are launched on-demand via wlr-which-key or keybinds.

**Window behavior:**
- Dialogs, popups, file choosers, settings windows float automatically
- Games workspace: no gaps, no rounding, full opacity
- Other workspaces: 3px gaps in, 6px gaps out
- Helium, steam apps: full opacity override
- Picture-in-Picture: floats and pins

### Noctalia (`modules/hjem/noctalia/`)

Shell UI — launcher, bar, lock screen, control center. Color scheme via kcolorscheme. Wallpaper from `~/.local/share/wallpapers/` with random rotation.

Settings live in `modules/hjem/noctalia/settings.json`.

### Ly

TUI login screen. Minimal, works with YubiKey auth.

### Theming

- GTK: adw-gtk3 dark theme, prefer-dark via dconf
- Cursors: phinger-cursors-dark (hyprcursor variant, custom derivation in `modules/hjem/xdg/xdg.nix`)
- Fonts: Terminess Nerd Font (UI), JetBrainsMono NFM (monospace)
- Qt: Qt6ct platform theme

## Development

### Claude Code (`claude-code.nix`)

AI-assisted development. Project management via `cc` command.

### Zed (`modules/hjem/zed/`)

GPU-accelerated GUI editor. LSP support via nixd, nil, alejandra, basedpyright, ruff. Config deployed via Hjem.

### Fresh (`modules/hjem/fresh-editor.nix`)

TUI editor with LSP and TypeScript plugin support. Wrapped with full LSP toolchain on PATH: nixd, nil, alejandra, basedpyright, ruff, vscode-langservers-extracted, hyprls, marksman, nufmt. Config at `~/.config/fresh/config.json`, deployed via Hjem as a writable copy.

### Ghostty (`modules/hjem/ghostty.nix`)

GPU-accelerated terminal. Noctalia theme.

### Nushell + Oh My Posh (`modules/hjem/nushell.nix`)

Nushell as daily driver with Oh My Posh prompt and carapace completions. Aliases and jj workflow functions defined here.

### Languages (`languages.nix`)

Java 21 (`jdk21`). `ns` — fzf-powered nix package search via nix-search-tv. Gated on `features.development`.

### Dev utilities

`fzf`, `jq`, `gh` (GitHub CLI), `alejandra` (nix formatter), `nix-index`.

## Gaming

### Steam (`steam.nix`)

Proton, Protontricks, Gamescope, controller support. 32-bit compat layers.

### Decky Loader (`modules/hjem/decky.nix`)

Steam plugin system. Systemd user service, web interface at localhost:8080 when Steam is running. GPL-2.0 licensed — no conflict with the MIT config (packaging isn't a derivative work).

### MangoHud (`modules/hjem/mangohud.nix`)

Performance overlay. 5 presets (0=off, 1=FPS only, 2=summary, 3=extended, 4=full). Toggle with Shift+F12, cycle presets with Shift+F2.

### Emulators (`gaming-packages.nix`)

RetroArch (16 cores, configs in `modules/hjem/retroarch.nix`), PPSSPP, DeSmuME, Ryujinx, ProtonUp-Qt.

## Media

### Audio

Pipewire + WirePlumber. Hardware mixing. Bluetooth audio (A2DP, HSP/HFP).

### Music

MPD service (`modules/hjem/mpd.nix`), Euphonica GTK4 client. Music directory at ~/Music.

### Music management (`scraping.nix`)

Beets for library management with MusicBrainz integration. `scrapem` for YouTube playlist → MP3. `scrapev` for video downloads.

### Media creation (`creation.nix`)

GIMP 3, OBS Studio, Video2x.

### Streaming

Stremio for video. Transmission for torrents.

## System

### File manager

Superfile TUI (`modules/hjem/superfile.nix`) — launched in a floating Ghostty window via Super+Space.

### Browser

Helium (`modules/hjem/helium.nix`) — Electron-based, Widevine CDM for DRM content.

### System monitoring

btop++ (`btop.nix`) — terminal system monitor with GPU support. LACT for AMD GPU control and monitoring, lives in the stash workspace.

### Fastfetch (`modules/hjem/fastfetch/`)

System info with custom AnomalOS logo (`nixos.png`).

### USB automount (`modules/hjem/udiskie.nix`)

udiskie auto-mounts USB drives with desktop notifications.

### Flatpak (`modules/hjem/flatpak.nix`)

Declarative Flatpak management via nix-flatpak. Sandboxed apps with Wayland/GPU permission overrides.

### KDE Connect (`modules/hjem/kdeconnect.nix`)

Phone/device integration and file transfer.

### VM support (`vm.nix`)

libvirtd + virt-manager when `vm = true`.

### Android webcam (`android-webcam.nix`)

Android phone as USB webcam via scrcpy when `androidWebcam = true`.

## ZFS

- `zroot` pool: system (/, /nix, /persist, /cache)
- Automated snapshots via sanoid — see [Backups](BACKUP.md)
- Compression (zstd), auto-trim, ARC caching
- Swappiness 10, zram swap (25% RAM, zstd compressed)

## Cachix binary caches

Pre-configured in rig.nix: cache.nixos.org, ezkea.cachix.org, nix-community.cachix.org, hyprland.cachix.org, lantian (attic).
