# Features & Components Guide

This guide provides comprehensive documentation of all features and components available in AnomalOS.

> **Note**: This configuration includes features tailored to my personal workflow. You may enable/disable features as needed, but some may require hardware-specific adjustments.

## Table of Contents

- [Security Features](#security-features)
- [Desktop Environment](#desktop-environment)
- [Development Tools](#development-tools)
- [Gaming & Media](#gaming--media)
- [Package Management](#package-management)
- [System Services](#system-services)

## Security Features

### YubiKey U2F Authentication

**Available in**: Rig configuration

**Features:**
- U2F authentication for login, sudo, and polkit
- Automatic login when registered YubiKey is present
- Dynamic auto-login management via systemd services
- Support for multiple YubiKeys

**Setup:**
```bash
# Register your YubiKey
mkdir -p ~/.config/Yubico
pamu2fcfg > ~/.config/Yubico/u2f_keys

# Add additional YubiKeys
pamu2fcfg -n >> ~/.config/Yubico/u2f_keys
```

**Services:**
- `yubikey-autologin-init.service`: Enables auto-login at boot if YubiKey present
- `yubikey-autologin-monitor.service`: Monitors YubiKey connection/disconnection

**Check Status:**
```bash
sudo journalctl -u yubikey-autologin-init
sudo journalctl -u yubikey-autologin-monitor
```

**Location**: `modules/security/yubikey.nix`

### Suricata IDS

**Available in**: All configurations (when security feature enabled)

**Features:**
- Real-time network intrusion detection
- Traffic monitoring and analysis
- Alert logging and reporting
- Automatic rule updates

**Monitoring:**
```bash
# Check Suricata status
sudo systemctl status suricata

# View alerts
sudo tail -f /var/log/suricata/fast.log

# View detailed logs
sudo tail -f /var/log/suricata/eve.json
```

**Configuration**: Alert on unusual network activity, logs to `/var/log/suricata/`

**Location**: `modules/security/suricata.nix`

### Firewall (nftables)

**Available in**: All configurations

**Features:**
- Restrictive default policies (drop all incoming)
- SSH on non-standard port 2222
- Custom gaming ports (23243-23262) for Divinity Original Sin 2
- Stateful connection tracking

**Port Configuration:**
- TCP 2222: SSH
- TCP 23243-23262: Gaming (Divinity Original Sin 2)

**Management:**
```bash
# Check firewall status
sudo nft list ruleset

# View open ports
sudo ss -tulpn
```

**Location**: `modules/security/firewall.nix`

### Kernel & System Hardening

**Available in**: All configurations

**Features:**
- Extensive sysctl security parameters
- SSH hardening with modern ciphers
- Secure PAM configuration
- Memory protection and randomization
- Network stack hardening

**Hardening Applied:**
- ASLR (Address Space Layout Randomization)
- Stack protection
- Kernel pointer hiding
- SYN flood protection
- ICMP rate limiting
- Restricted kernel logs

**Location**: `modules/security/hardening.nix`

### DNSCrypt-Proxy Encrypted DNS

**Available in**: All configurations (when dnscrypt security feature enabled)

**Features:**
- Encrypted DNS resolver using dnscrypt-proxy
- Dual upstream servers (Cloudflare, Quad9)
- DoH/DNSCrypt protocols prevent ISP surveillance
- Aggressive caching (4096 entries, 40min-24hr TTL)
- DNSSEC validation required
- Quad9 threat intelligence for malware blocking

**Configuration:**
```bash
# Check service status
sudo systemctl status dnscrypt-proxy

# View logs
sudo journalctl -u dnscrypt-proxy
```

**Location**: `modules/security/dnscrypt-proxy.nix`

## Desktop Environment

### Hyprland Compositor

**Available in**: All configurations (when desktop feature enabled)

**Features:**
- Wayland compositor with dwindle tiling layout
- GPU acceleration
- Named workspace organization
- Window animations and effects
- Screen capture utilities (grim, slurp)
- Special workspace for utility applications

**Workspace Organization:**

The system uses a named workspace scheme designed for efficient workflow management:

1. **comms** (Super+1): Communication apps (Discord/Vesktop)
2. **dev** (Super+2): Development environment (Zed, Ghostty terminals)
3. **games** (Super+3): Gaming (Steam, game launchers, game windows)
4. **media** (Super+4): Media playback (VLC, streaming apps)
5. **web** (Super+5): Web browsing (Helium, Firefox, Chrome apps)
6. **control-panel** (Super+Grave): Special workspace for utilities

**Control-Panel Utilities:**
- pavucontrol: Audio volume control
- nmtui: Network configuration
- bluetui: Bluetooth management
- btop: System resource monitor
- qalculate-gtk: Calculator
- piper: Gaming mouse configuration
- kwalletmanager: Password wallet manager

**Workspace Navigation:**
- `Super+1-5`: Jump to named workspace
- `Super+PgUp/PgDn`: Cycle through workspaces
- `Super+MouseWheel`: Cycle through workspaces
- `Super+Grave`: Toggle control-panel overlay

**Auto-Launch:**
Applications automatically open on their designated workspaces:
- Steam, Vesktop, VLC launch at login on their respective workspaces
- System boots to comms workspace after auto-launch completes
- Utility apps open on control-panel when launched via desktop entries or waybar

**Window Behavior:**
- Dialogs float with natural Wayland positioning (xdg-dialog protocol)
- Auth dialogs (KWallet) stay focused to prevent credential exposure
- Games workspace: no gaps, no rounding, full opacity
- Other workspaces: 1px gaps in, 2px gaps out, slight transparency (0.90 active, 0.80 inactive)
- Media/streaming apps: full opacity overrides for optimal viewing

**Included Utilities:**
- `grim`: Screenshot utility
- `slurp`: Region selector
- `wl-clipboard`: Clipboard manager
- `hyprpicker`: Color picker
- `swww`: Animated wallpaper daemon

**Configuration:**
- System-level: `modules/desktop/hyprland.nix`
- Desktop entries: `modules/desktop/default.nix`
- User-level: `home.nix` (for additional customization)

### Waybar Status Bar

**Available in**: All configurations

**Features:**
- System monitoring (CPU, memory, disk)
- Network status
- Audio controls
- Workspace indicators
- Styled with Stylix theme

**Configuration**: `home.nix` under `programs.waybar`

### SDDM Display Manager

**Available in**: All configurations

**Features:**
- Graphical login screen
- YubiKey authentication integration (when enabled)
- Themed with Stylix
- Session selection

**Location**: `modules/desktop/default.nix`

### Stylix Theming

**Available in**: All configurations

**Features:**
- Consistent theming across all applications
- Anomal-16 color scheme
- Automatic color generation from wallpaper
- GTK and Qt theme integration
- Terminal and editor theming

**Current Theme**: Anomal-16 (dark)
- Base colors: Deep purple backgrounds
- Accent colors: Pink, cyan, yellow highlights
- Wallpapers: Rotating from `~/.local/share/wallpapers/` every 3 minutes

**Customization:**
```nix
# Change color scheme in modules/desktop/stylix.nix
stylix.base16Scheme = {
  base00 = "1b002b";  # Background
  base05 = "b392f0";  # Foreground
  # ... more colors
};
```

**Change wallpapers**: Add images to `~/.local/share/wallpapers/`

**Location**: `modules/desktop/stylix.nix`

## Development Tools

### Claude Code

**Features:**
- AI-powered development assistant
- Enhanced project management via `cc` command
- Global project navigation and organization
- Pre-approved commands for autonomous operation
- MCP server integration
- Custom slash commands

**Commands:**
```bash
cc              # Interactive project menu
cc [project]    # Open specific project
cc list         # List all projects
cc new [name]   # Create new project
cc status       # Show system status
```

**Global Configuration:**
- Location: `~/claude-projects/.claude/`
- Settings: `settings.local.json` (permissions, MCP servers)
- Commands: `.claude/commands/*.md`

**Implementation**:
- System: `modules/development/claude-code.nix`
- Enhanced: `modules/claude-code-enhanced/default.nix`

### Editors

**Zed**
- Fast, native editor with GPU acceleration
- Language server protocol support
- Integrated terminal and git
- Extension support

**Configuration**: `modules/development/editors.nix`

### Terminal & Shell

**Ghostty Terminal**
- GPU-accelerated rendering
- Ligature and font fallback support
- Image protocol support for previews

**Fish Shell**
- Intelligent autocompletions
- Syntax highlighting
- Command history search
- Web-based configuration

**Starship Prompt**
- Fast, customizable prompt
- Git integration
- Directory truncation
- Language version display

**Configuration**: `home.nix`

### File Managers

**Yazi**
- Modern terminal file manager
- Vim-style keybindings with custom mappings
- File previews and image display
- Custom theme integration with Stylix
- Custom keymap configuration (see `modules/desktop/yazi/keymap.toml`)

**Configuration**: `modules/desktop/default.nix` and `modules/desktop/yazi/`

### System Information

**Fastfetch**
- Fast system information tool
- Custom AnomalOS logo display (AnomLogo.png)
- Displays: OS, host, kernel, uptime, packages, shell, display, WM, terminal, CPU, GPU, memory, swap, disk

**Configuration**: `modules/desktop/default.nix`

### Development Languages & Tools

**Installed by default:**
- **Node.js**: JavaScript/TypeScript development
- **Python 3**: Python development with uv package manager
- **Rust**: Systems programming with Cargo
- **Nix**: Configuration language
- **Java**: JDK 21

**Language Servers:**
- `nixd`: Nix language server
- `hyprls`: Hyprland configuration language server

**Code Formatting:**
- `alejandra`: Nix code formatter

**Version Control:**
- Git with custom aliases
- GitHub CLI (`gh`)

**Development Utilities:**
- `btop`: Resource monitor
- `fzf`: Fuzzy finder
- `jq`: JSON processor
- `tldr`: Simplified man pages
- `ns`: Interactive NixOS package search (nix-search-tv wrapper)
- `uv`: Fast Python package installer and resolver

**Configuration**: `modules/development/languages.nix`

## Gaming & Media

### Steam

**Available in**: All configurations (when gaming feature enabled)

**Features:**
- Proton compatibility layer for Windows games
- Protontricks for per-game Proton management
- Gamescope session support
- Remote Play with open firewall
- Dedicated server support
- Local network game transfers
- Hardware compatibility layers (32-bit support)
- Controller support (extest enabled)

**Configuration**: `modules/gaming/steam.nix`

### Anime Game Launchers

**aagl-gtk-on-nix**
- Native Linux launchers for anime games
- Conditionally enabled via gaming feature flag
- Binary cache support for fast installation

**Configuration**: `modules/gaming/aagl.nix`

### Emulators

**PPSSPP**
- PlayStation Portable emulator
- High-resolution rendering
- Save states

**DeSmuME**
- Nintendo DS emulator
- Touchscreen support
- Save states

**Ryujinx**
- Nintendo Switch emulator
- Modern yuzu alternative

**Lutris**
- Game management platform
- Wine integration
- Multiple emulators support

**ProtonUp-Qt**
- Proton-GE and Wine-GE version manager
- Easy compatibility tool updates for Steam

**RetroArch**
- Multi-system emulator with libretro cores
- Automated playlist generation for 16 platforms
- CRC32 checksums for metadata matching

**Configuration**: `modules/gaming/default.nix`

### Media Tools

**Audio:**
- Pipewire: Modern audio system with low-latency
- WirePlumber: Pipewire session manager
- Hardware mixing support

**Video:**
- VLC: Full-featured media player with codec support

**Streaming:**
- OBS Studio: Screen recording and streaming

**Graphics:**
- GIMP 3: Image editing with plugins

**File Sharing:**
- Transmission: BitTorrent client (GTK interface)

**Music Management:**
- Beets: Music library manager with MusicBrainz integration
- Automatic tagging, album art, and file organization
- YouTube playlist downloader with MP3 conversion (scrapem command)

**Configuration**:
- Desktop media tools: `modules/desktop/media.nix` (OBS, GIMP, Video2x)
- Music/playlist tools: `modules/development/media.nix` (Beets, yt-dlp, download-playlist script)

### Applications

**Communication:**
- Vesktop: Discord client

**Productivity:**
- Anki: Flashcard application for learning
- Qalculate: Advanced calculator

**Utilities:**
- Pavucontrol: PulseAudio/PipeWire volume control
- Piper: Gaming mouse configuration (Logitech, Razer, etc)
- Qview: Minimal image viewer
- Okular: Full-featured PDF viewer with KDE integration

**Gaming Tools:**
- Elite Dangerous Market Connector: Trade route planning
- min-ed-launcher: Minimal CLI launcher for Elite Dangerous
- ed-odyssey-materials-helper: Materials tracking for Elite Dangerous

**Configuration**: `modules/desktop/default.nix` and `modules/desktop/media.nix`

## Package Management

### Nix Flakes

**Features:**
- Reproducible system configuration
- Pinned dependencies via `flake.lock`
- Easy configuration versioning
- Atomic updates and rollbacks

**Commands:**
```bash
nix flake update          # Update all inputs
nix flake lock            # Update lock file
nix flake show            # Show flake outputs
nix flake check           # Validate flake
```

### Home Manager

**Features:**
- User-space package management
- Dotfile management
- Per-user service management
- Configuration isolation

**Management:**
```bash
home-manager switch       # Apply home configuration
home-manager generations  # List generations
```

### Flatpak

**Features:**
- Declarative Flatpak management via nix-flatpak
- Sandboxed application support with automatic updates
- Permission overrides for Wayland and GPU acceleration
- Version pinning and multi-app declaration

**Configuration**: Managed declaratively in `modules/desktop/flatpak.nix`

**Manual Commands:**
```bash
flatpak search [app]      # Search for applications
flatpak list              # List installed apps
```

### Cachix Binary Caches

**Configured caches:**
- `cache.nixos.org`: Official NixOS binary cache
- `nix-community.cachix.org`: Community packages
- `hyprland.cachix.org`: Hyprland compositor and tools
- `ezkea.cachix.org`: Anime game launchers (aagl-gtk-on-nix)
- `cache.flakehub.com`: FlakeHub binary cache

**Benefit**: Faster builds by using pre-built binaries

**Configuration**: `configuration.nix` (nix.settings.substituters)

### ZFS Automated Snapshots

**Features:**
- Automated hourly snapshots via sanoid
- Multi-tier retention (hourly, daily, weekly, monthly)
- Copy-on-write efficiency (minimal space usage)
- Automatic pruning of old snapshots

**Snapshot retention policies:**
- **zroot/persist** (critical): 50 hourly, 15 daily, 3 weekly, 1 monthly
- **zroot/root** (important): 24 hourly, 7 daily, 2 weekly, 1 monthly
- **zgames/games** (important): 24 hourly, 7 daily, 2 weekly, 1 monthly
- **zroot/nix** (standard): 12 hourly, 3 daily, 1 weekly

**Management:**
```bash
# List all snapshots
zfs list -t snapshot

# Browse snapshot contents
cd /persist/.zfs/snapshot
ls -la

# Restore file from snapshot
cp /persist/.zfs/snapshot/autosnap_2025-12-11_16:00:00_hourly/path/to/file ~/restored-file

# Check sanoid status
systemctl status sanoid.service
```

**Configuration**: `modules/core/zfs-snapshots.nix`

**Note**: See [BACKUP.md](BACKUP.md) for complete snapshot management and recovery guide

## System Services

### Automatic Garbage Collection

**Features:**
- Daily automatic cleanup
- Removes system generations older than 90 days
- Store optimization
- Freed space reporting

**Manual cleanup:**
```bash
recycle                           # Keep last 10 generations, remove older
sudo nix-collect-garbage -d       # Clean all old generations
sudo nix-collect-garbage --delete-older-than 30d  # Custom age
```

**Configuration**: `modules/core/nix.nix`

### Bluetooth

**Available in**: All configurations (when bluetooth hardware enabled)

**Features:**
- Bluetooth 5.0+ support
- PipeWire audio routing
- `bluetui`: Terminal UI for Bluetooth management

**Management:**
```bash
bluetui         # Launch Bluetooth TUI
bluetoothctl    # CLI management
```

### System Update Workflow

**Interactive update function:**
```bash
rig-up          # Update + test + prompt to switch (Rig)
```

**Process:**
1. Updates all flake inputs
2. Tests new configuration
3. Prompts to switch if test succeeds
4. You can decline to keep current configuration

**Manual workflow:**
```bash
cd ~/dotfiles
nix flake update                      # Update dependencies
sudo nixos-rebuild test --flake .#Rig # Test changes
sudo nixos-rebuild switch --flake .#Rig # Apply if good
```

## Hardware Support

### GPU Support

**AMD:**
- Mesa drivers
- ROCm for compute workloads
- Vulkan support
- Hardware video acceleration

**NVIDIA:**
- Proprietary drivers
- CUDA support
- Vulkan support
- Hardware video acceleration

### Audio

**Pipewire:**
- ALSA compatibility
- PulseAudio compatibility
- JACK compatibility
- Low-latency audio
- Bluetooth audio (A2DP, HSP/HFP)

### Network

**NetworkManager:**
- WiFi management
- Ethernet management
- VPN support
- Connection profiles

## Performance Optimizations

### ZFS Filesystem

**Features:**
- Copy-on-write filesystem with automated snapshots
- Data integrity verification (checksums)
- Compression (zstd) for space savings
- Auto-trim for SSD health and performance
- ARC caching for improved read performance
- Automated snapshots via sanoid (hourly, daily, weekly, monthly)

**Configuration:**
- Root pool: `zroot` (system, nix, cache, persist)
- Games pool: `zgames` (optional, dedicated gaming storage)
- Snapshots: Automated via `modules/core/zfs-snapshots.nix`
- Location: `hardware-configuration-zfs.nix`

### Kernel Configuration

**Linux 6.17:**
- Modern kernel with latest hardware support
- Security hardening via kernel parameters
- ZFS module support

**Configuration**: `modules/core/boot.nix`

### System Tuning

**Memory:**
- ZFS ARC cache: Dynamic (50% of RAM, automatically managed)
- Swappiness reduced to 10 for better responsiveness
- Zram swap (25% of RAM) with zstd compression

**Download Buffer:**
- 256MB buffer for faster downloads

**Configuration**: Various modules

## Next Steps

- Read [Configuration Guide](CONFIGURATION.md) to customize features
- Check [Customization Guide](CUSTOMIZATION.md) for advanced modifications
- See [Troubleshooting Guide](TROUBLESHOOTING.md) if features aren't working

---

**Note**: All features are designed to work together but can be selectively disabled via feature toggles in `configuration.nix`.
