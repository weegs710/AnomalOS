# Features & Components Guide

This guide documents all features and components available in AnomalOS.

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

**Location**: `features/security/yubikey.nix`

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

**Location**: `features/security/suricata.nix`

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

**Location**: `features/security/firewall.nix`

### Kernel & System Hardening

**Available in**: All configurations

**Features:**
- Extensive sysctl security parameters
- SSH hardening configuration
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

**Location**: `features/security/hardening.nix`

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

**Location**: `features/security/dnscrypt-proxy.nix`

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

The system uses a named workspace scheme:

1. **comms** (Super+1): Communication apps (Discord/Vesktop)
2. **dev** (Super+2): Development environment (Zed, Ghostty terminals)
3. **games** (Super+3): Gaming (Steam, game launchers, game windows)
4. **media** (Super+4): Media playback (Euphonica music player, Stremio)
5. **web** (Super+5): Web browsing (Helium)
6. **control-panel** (Super+Grave): Special workspace for utilities

**Control-Panel Utilities:**
- pavucontrol: Audio volume control
- nmtui: Network configuration
- blueman-manager: Bluetooth management (GTK interface)
- mission-center: GUI system resource monitor with GPU monitoring (GTK4/Libadwaita)
- lact: AMD GPU control, monitoring, and overclocking
- qalculate-gtk: Calculator
- piper: Gaming mouse configuration (Logitech, Razer, etc)

**Workspace Navigation:**
- `Super+1-5`: Jump to named workspace
- `Super+Shift+1-5`: Move active window to workspace
- `Super+PgUp/PgDn`: Cycle through workspaces
- `Super+Tab/Shift+Tab`: Cycle workspaces forward/backward
- `Super+MouseWheel`: Cycle through workspaces
- `Super+Grave`: Toggle control-panel overlay

**Quick Launch (F-keys aligned to workspaces):**
- `Super+F1`: Vesktop (workspace 1 - comms)
- `Super+F2`: Zed editor (workspace 2 - dev)
- `Super+F3`: Steam (workspace 3 - games)
- `Super+F4`: Euphonica music player (workspace 4 - media)
- `Super+F5`: Helium web browser (workspace 5 - web)
- `Super+F6`: Mission Center system monitor (control-panel)

**Core Applications:**
- `Super+Return`: Terminal (Ghostty)
- `Super+Space`: File manager (Superfile TUI)
- `Super+Super_L`: Noctalia shell launcher toggle

**Window Management:**
- `Super+Escape`: Close active window
- `Super+F`: Fullscreen toggle
- `Super+G`: Float toggle
- `Super+Backspace`: Enter resize mode (arrow keys to resize, Esc/Return to exit)
- `Super+Arrow Keys`: Move focus
- `Super+Shift+Arrow Keys`: Move window

**System Controls:**
- `Ctrl+Alt+L`: Lock screen (noctalia shell)
- `Ctrl+Alt+Delete`: Logout menu (wlogout)
- `Super+Home/End`: Volume up/down
- `Super+Pause`: Audio mute toggle

**Screenshots:**
- `Print`: Region to clipboard
- `Shift+Print`: Region to ~/Pictures
- `Ctrl+Print`: Active window to clipboard

**Auto-Launch:**
Applications automatically open on their designated workspaces:
- Steam and Vesktop launch at login on their respective workspaces
- System boots to comms workspace after auto-launch completes
- Utility apps open on control-panel when launched via desktop entries

**Window Behavior:**
- Dialogs float with natural Wayland positioning (xdg-dialog protocol)
- Games workspace: no gaps, no rounding, full opacity
- Other workspaces: 3px gaps in, 6px gaps out, slight transparency (0.94 active, 0.90 inactive)
- Media/streaming apps: full opacity overrides
- Floating windows: always full opacity

**Included Utilities:**
- `grim`: Screenshot utility
- `slurp`: Region selector
- `wl-clipboard`: Clipboard manager
- `hyprpicker`: Color picker
- `swww`: Animated wallpaper daemon

**Configuration:**
- System-level: `features/hyprland/system.nix` (enables Hyprland, XDG portals, PAM)
- User-level: `features/hyprland/` (modular organization):
  - `config.nix`: Hyprland settings (monitor, env, animations, etc.)
  - `keybinds.nix`: All keybindings and submaps
  - `rules.nix`: Window rules
  - `wallpaper.nix`: swww service (managed by noctalia)

### Noctalia Shell UI

**Available in**: All configurations (when desktop feature enabled)

**Features:**
- Dynamic shell UI with launcher, bar, and notification system
- Matugen-based color scheme generation
- Persistent GUI settings via NOCTALIA_SETTINGS_FALLBACK
- GTK4/Libadwaita integration with adw-gtk3 theme
- Wave visualizer for media playback
- Configurable wallpaper rotation (10-minute intervals with wave transitions)
- Custom panel layouts and styling

**Configuration**: `features/noctalia/`
  - `default.nix`: Noctalia module with systemd service configuration
  - `settings.nix`: Declarative GUI settings (launcher, bar, appearance, wallpaper)

### Ly Display Manager

**Available in**: All configurations

**Features:**
- TUI login screen with minimal footprint
- YubiKey authentication integration (when enabled)
- Session selection
- Wayland session support

**Location**: `features/core/desktop-services.nix`

### Theming System

**Available in**: All configurations

**Primary Theming:**
- **Noctalia shell**: Dynamic theming via matugen color scheme generation
- **Theme**: Fruit Salad scheme with SpaceMono Nerd Font family
- **GTK**: adw-gtk3 dark theme with prefer-dark dconf configuration
- **Qt**: Qt6ct platform theme with environment variable support

**Legacy Theming (disabled):**
- Stylix is disabled system-wide but remains available for potential re-enablement
- Axion custom base16 color scheme files preserved in repository

**Font Configuration:**
- **Monospace**: SpaceMono Nerd Font (noctalia)
- **Terminal**: Size 13 in Ghostty

**Wallpapers**: Managed by noctalia with 10-minute rotation intervals, wave transitions

**Location**: `features/noctalia/`

## Development Tools

### Claude Code

**Features:**
- AI-powered development assistant
- Project management via `cc` command
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
- System: `features/development/claude-code.nix`
- Module: `features/development/claude-code-enhanced/default.nix`

### Editors

**Zed**
- Editor with GPU acceleration
- Language server protocol support
- Integrated terminal and git
- Extension support

**Configuration**: `features/editors/zed.nix`

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

**Oh My Posh Prompt**
- Prompt with JSON schema configuration
- Git integration with branch and status display
- Directory truncation and navigation
- Language/tooling version detection (Node, Python, etc.)

**Configuration**: `features/core/oh-my-posh.nix`

### File Managers

**Superfile**
- Modern TUI file manager with vim-style navigation
- Dual-pane interface for efficient file operations
- Image and media preview support
- Quick access via Super+Space keybind
- Launches in floating Ghostty terminal window
- Configured with custom opener integrations for Zed editor

**Configuration**: `features/core/superfile.nix`

### Web Browsers

**Helium**
- Lightweight web browser built on Electron
- Widevine CDM support for DRM-protected content (streaming services, etc.)
- Dedicated workspace 5 (web) integration
- Auto-launches on login for quick access
- Full opacity override for media playback
- Keyboard-friendly navigation

**Configuration**: `features/desktop/helium.nix`

### System Monitoring

**btop++**
- Modern terminal-based system monitor
- Real-time CPU, memory, disk, and network monitoring
- Process management with detailed resource usage
- GPU monitoring for AMD/NVIDIA hardware
- Mouse-driven interface with vim-like keybindings
- Quick launch via desktop menu or terminal

**Configuration**: `features/desktop/btop.nix`

**LACT (Linux AMDGPU Control Tool)**
- AMD GPU control and monitoring tool
- Power management and fan curve configuration
- GPU overclocking and undervolting support
- Temperature and power consumption monitoring
- Launched via control-panel workspace (Super+Grave)

### System Information

**Fastfetch**
- System information tool
- Custom AnomalOS logo display (AnomLogo.png)
- Displays: OS, host, kernel, uptime, packages, shell, display, WM, terminal, CPU, GPU, memory, swap, disk

**Configuration**: `features/desktop/fastfetch.nix`

### Development Languages & Tools

**Installed by default:**
- **Node.js**: JavaScript/TypeScript development
- **Python 3**: Python development with uv package manager
- **Rust**: Systems programming with Cargo
- **Nix**: Configuration language
- **Java**: JDK 21

**Language Servers:**
- `nixd`: Nix language server with nixpkgs integration
- `nil`: Nix language server with flake diagnostics (runs alongside nixd)
- `hyprls`: Hyprland configuration language server

**Code Formatting:**
- `alejandra`: Nix code formatter

**Version Control:**
- Git with custom aliases
- GitHub CLI (`gh`)

**Development Utilities:**
- `fzf`: Fuzzy finder
- `jq`: JSON processor
- `tldr`: Simplified man pages
- `ns`: Interactive NixOS package search (nix-search-tv wrapper)
- `uv`: Python package installer and resolver

**Configuration**: `features/development/languages.nix`

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

**Configuration**: `features/gaming/steam.nix`

### Decky Loader Steam Plugin System

**Available in**: All configurations (when gaming feature enabled)

**Features:**
- Steam plugin system for Steam Deck-like functionality on desktop
- v3.2.1 packaged via fetchurl with hash verification
- Systemd user service with NixOS-compatible PATH configuration
- ~/homebrew directory structure for plugins and services
- Steam CEF remote debugging for plugin UI injection
- Firewall ports 8080 and 1337 opened for web interface
- Python3, systemd, coreutils, curl, and git in service PATH for plugin operations
- autoPatchelfHook for proper binary dependencies (zlib, gcc libs)

**Management:**
- Access at http://localhost:8080 when Steam is running
- Plugin installation and updates via Decky web interface
- Service managed via systemd: `systemctl --user status decky-loader`

**Configuration**: `features/gaming/decky-loader.nix`

### MangoHud Performance Overlay

**Available in**: All configurations (when gaming feature enabled)

**Features:**
- Steam Deck-style performance overlay with 5 preset levels
- Integrated into Steam FHS environment via extraPackages
- Real-time FPS, GPU/CPU stats, RAM usage, temperatures
- Extended metrics: VRAM, power consumption, frame timing, I/O
- Full detailed mode: clocks, core loads, driver info
- Configuration files in ~/.config/MangoHud/

**Preset Levels:**
- Preset 0: Overlay disabled
- Preset 1: FPS only (minimal)
- Preset 2: Horizontal summary (GPU/CPU stats, RAM, FPS)
- Preset 3: Extended metrics (temps, VRAM, power, frame timing)
- Preset 4: Full detailed (clocks, core loads, I/O, driver info)

**Usage:**
- Switch presets with Shift+F2 in-game
- Toggle overlay with Shift+F12

**Configuration**: `features/gaming/mangohud.nix`

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
- Yuzu alternative

**ProtonUp-Qt**
- Proton-GE and Wine-GE version manager
- Compatibility tool updates for Steam

**RetroArch**
- Multi-system emulator with libretro cores
- Automated playlist generation for 16 platforms
- CRC32 checksums for metadata matching

**Configuration**: `features/gaming/default.nix`

### Media Tools

**Audio:**
- Pipewire: Audio system
- WirePlumber: Pipewire session manager
- Hardware mixing support

**Music:**
- MPD (Music Player Daemon): Systemd user service for music playback
- Euphonica: GTK4/Libadwaita MPD client
- Music directory: ~/Music with Artist/Album folder structure

**Streaming:**
- Stremio: Media center for streaming video content
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
- MPD service: `features/media/mpd.nix`
- Desktop media tools: `features/media/creation.nix` (OBS, GIMP, Video2x)
- Music/playlist tools: `features/development/media.nix` (Beets, yt-dlp, scrapem/scrapev commands)

### Applications

**Communication:**
- Vesktop: Discord client

**Productivity:**
- Anki: Flashcard application for learning
- Qalculate: Calculator

**Utilities:**
- Pavucontrol: PulseAudio/PipeWire volume control
- Piper: Gaming mouse configuration (Logitech, Razer, etc)
- Qview: Minimal image viewer
- Okular: Full-featured PDF viewer with KDE integration

**Gaming Tools:**
- Elite Dangerous Market Connector: Trade route planning
- min-ed-launcher: Minimal CLI launcher for Elite Dangerous
- ed-odyssey-materials-helper: Materials tracking for Elite Dangerous

**Configuration**: `features/core/desktop-packages.nix` and `features/media/creation.nix`

## Package Management

### Nix Flakes

**Features:**
- Reproducible system configuration
- Pinned dependencies via `flake.lock`
- Configuration versioning via git
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

**Configuration**: Managed declaratively in `features/desktop/flatpak.nix`

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

**Benefit**: Use pre-built binaries instead of building from source

**Configuration**: `configuration.nix` (nix.settings.substituters)

### ZFS Automated Snapshots

**Features:**
- Automated hourly snapshots via sanoid
- Multi-tier retention (hourly, daily, weekly, monthly)
- Copy-on-write (space usage grows only with changed data)
- Automatic pruning of old snapshots

**Snapshot retention policies:**
- **zroot/persist** (critical): 50 hourly, 15 daily, 3 weekly, 1 monthly
- **zroot/root** (important): 24 hourly, 7 daily, 2 weekly, 1 monthly
- **zgames/games** (games): 12 hourly, 7 daily, 1 weekly, 0 monthly
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

**Configuration**: `features/core/zfs.nix`

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

**Configuration**: `features/core/nix-daemon.nix`

### Bluetooth

**Available in**: All configurations (when bluetooth hardware enabled)

**Features:**
- Bluetooth 5.0+ support
- PipeWire audio routing
- Blueman: GTK Bluetooth management interface

**Management:**
```bash
blueman-manager     # Launch Blueman GUI
bluetoothctl        # CLI management
```

### USB Device Automount

**Available in**: All configurations (when desktop feature enabled)

**Features:**
- Automatic mounting of USB drives via udiskie service
- Desktop notifications for mount/unmount events
- udisks2 backend for device management
- Passwordless mounting for removable devices
- Automatic cleanup on device removal

**Service:**
```bash
# Check udiskie status
systemctl --user status udiskie

# View mount events
journalctl --user -u udiskie
```

**Configuration**: `features/desktop/udiskie.nix`

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
- ARC caching
- Automated snapshots via sanoid (hourly, daily, weekly, monthly)

**Configuration:**
- Root pool: `zroot` (system, nix, cache, persist)
- Games pool: `zgames` (optional, dedicated gaming storage)
- Snapshots: Automated via `features/core/zfs.nix`
- Location: `hardware-configuration-zfs.nix`

### Kernel Configuration

**Linux 6.18+ (xanmod):**
- Xanmod kernel with additional patches
- Hardware support
- Security hardening via kernel parameters
- ZFS module support

**Configuration**: `features/core/boot.nix`

### System Tuning

**Memory:**
- ZFS ARC cache: Dynamic (50% of RAM, automatically managed)
- Swappiness: 10
- Zram swap (25% of RAM) with zstd compression

**Download Buffer:**
- 256MB buffer

**Configuration**: Various modules

## Next Steps

- Read [Configuration Guide](CONFIGURATION.md) to customize features
- Check [Customization Guide](CUSTOMIZATION.md) for modifications
- See [Troubleshooting Guide](TROUBLESHOOTING.md) if features aren't working

---

**Note**: All features are designed to work together but can be selectively disabled via feature toggles in `configuration.nix`.
