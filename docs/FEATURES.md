# Features & Components Guide

This guide provides comprehensive documentation of all features and components available in AnomalOS.

> **Note**: This configuration includes features tailored to my personal workflow. You may enable/disable features as needed, but some may require hardware-specific adjustments.

## Table of Contents

- [Security Features](#security-features)
- [Desktop Environment](#desktop-environment)
- [AI Development Tools](#ai-development-tools)
- [Development Tools](#development-tools)
- [Gaming & Media](#gaming--media)
- [Package Management](#package-management)
- [System Services](#system-services)

## Security Features

### YubiKey U2F Authentication

**Available in**: Rig, Guard configurations

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

## Desktop Environment

### Hyprland Compositor

**Available in**: All configurations (when desktop feature enabled)

**Features:**
- Wayland compositor with tiling capabilities
- GPU acceleration
- Multiple workspace support
- Window animations and effects
- Screen capture utilities (grim, slurp)

**Included Utilities:**
- `grim`: Screenshot utility
- `slurp`: Region selector
- `wl-clipboard`: Clipboard manager
- `hyprpicker`: Color picker
- `hyprpaper`: Wallpaper manager

**Configuration:**
- System-level: `modules/desktop/hyprland.nix`
- User-level: `home.nix` (for custom keybindings and settings)

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
- Purple Colony color scheme
- Automatic color generation from wallpaper
- GTK and Qt theme integration
- Terminal and editor theming

**Current Theme**: Purple Colony (dark)
- Base colors: Deep purple backgrounds
- Accent colors: Pink, cyan, yellow highlights
- Wallpaper: `AnomalOS.jpeg`

**Customization:**
```nix
# Change color scheme in modules/desktop/stylix.nix
stylix.base16Scheme = {
  base00 = "1b002b";  # Background
  base05 = "b392f0";  # Foreground
  # ... more colors
};

# Change wallpaper
stylix.image = ./your-image.jpg;
```

**Location**: `modules/desktop/stylix.nix`

## AI Development Tools

### Claude Code

**Available in**: Rig, Hack configurations

**Features:**
- AI-powered development assistant
- Enhanced project management via `cc` command
- Global project navigation and organization
- Pre-approved commands for autonomous operation
- MCP server integration (Serena)
- Specialized subagents (validation, documentation, NixOS config)
- Custom slash commands

**Commands:**
```bash
cc              # Interactive project menu
cc [project]    # Open specific project
cc list         # List all projects
cc new [name]   # Create new project
cc status       # Show system status
```

**Slash Commands:**
- `/primer`: Prime context for codebase understanding
- `/analyze [component]`: Deep component analysis
- `/generate [spec]`: Generate Product Requirements Prompt
- `/execute [prp]`: Execute implementation from PRP

**Global Configuration:**
- Location: `~/claude-projects/.claude/`
- Settings: `settings.local.json` (permissions, MCP servers)
- Commands: `.claude/commands/*.md`

**Implementation**:
- System: `modules/development/claude-code.nix`
- Enhanced: `modules/claude-code-enhanced/default.nix`

### Ollama + Open WebUI

**Available in**: All configurations (when aiAssistant feature enabled)

**Features:**
- Local AI model serving (Ollama)
- Web-based chat interface (Open WebUI)
- CLI assistant with nix-expert model
- ROCm support for AMD GPUs
- Custom NixOS expert model

**Commands:**
```bash
klank           # Open Web UI in browser
klank-cli       # Launch CLI assistant
ai              # Alias for klank-cli
ai-cli          # Alias for klank-cli
ai-web          # Alias for klank

# Model management
ollama list                # List installed models
ollama pull [model]        # Download model
deploy-ai-models          # Deploy custom models
```

**Services:**
- `ollama.service` (user): Ollama model server on port 11434
- `open-webui.service` (user): Web UI on port 8080

**Custom Model:**
- `nix-expert`: Specialized NixOS configuration assistant
- Based on configurable base model
- System prompt focused on NixOS expertise

**Configuration:**
```bash
# Check services
systemctl --user status ollama
systemctl --user status open-webui

# View logs
journalctl --user -u ollama
journalctl --user -u open-webui
```

**AMD GPU Support:**
- Mesa drivers with GPU acceleration
- ROCm compute libraries removed to prevent frequent rebuilds
- Basic GPU support remains for desktop acceleration

**Location**: `modules/development/ai-assistant.nix`

## Development Tools

### Editors

**VSCodium**
- GitHub Copilot support enabled
- Custom authentication integration
- Extension support

**Configuration**: `modules/development/editors.nix`

### Terminal & Shell

**Kitty Terminal**
- GPU-accelerated rendering
- Ligature support
- Image display support
- Multiplexing capabilities

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
- VSCode-style keybindings (arrow keys, Ctrl+C/V/X, Ctrl+T for tabs)
- File previews and image display
- Custom theme integration with Stylix
- Custom keymap configuration (see `modules/desktop/yazi/keymap.toml`)

**Thunar**
- GUI file manager fallback
- Volume management support
- File archiving with file-roller integration

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
- `nil`: Nix language server
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

### Emulators

**PPSSPP**
- PlayStation Portable emulator
- High-resolution rendering
- Save states

**DeSmuME**
- Nintendo DS emulator
- Touchscreen support
- Save states

**Ryubing**
- Nintendo Switch emulator
- Modern yuzu alternative

**Lutris**
- Game management platform
- Wine integration
- Multiple emulators support

**ProtonUp-Qt**
- Proton-GE and Wine-GE version manager
- Easy compatibility tool updates for Steam

**Note**: RetroArch is temporarily disabled due to upstream build issues

**Configuration**: `modules/gaming/default.nix`

### Media Tools

**Audio:**
- Pipewire: Modern audio system with low-latency
- WirePlumber: Pipewire session manager
- Hardware mixing support

**Video:**
- MPV: Minimal video player with hardware acceleration

**Streaming:**
- OBS Studio: Screen recording and streaming

**Graphics:**
- GIMP 3: Image editing with plugins

**File Sharing:**
- Transmission: BitTorrent client (GTK interface)

**Configuration**: `modules/desktop/media.nix`

### Applications

**Communication:**
- Vesktop: Discord client

**Productivity:**
- Anki: Flashcard application for learning
- Qalculate: Advanced calculator
- Alarm Clock Applet: Desktop alarm and timer

**Utilities:**
- Pavucontrol: PulseAudio/PipeWire volume control
- Piper: Gaming mouse configuration (Logitech, Razer, etc)
- Qview: Minimal image viewer
- Zathura: Lightweight PDF viewer

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
- Sandboxed application support
- Independent application updates
- Flathub repository access

**Commands:**
```bash
flatpak search [app]      # Search for applications
flatpak install [app]     # Install application
flatpak list              # List installed apps
```

### Cachix Binary Caches

**Configured caches:**
- `nix-community`: Community packages
- `hyprland`: Hyprland compositor and tools

**Benefit**: Faster builds by using pre-built binaries

**Configuration**: `modules/core/nix.nix`

### Restic Backups

**Features:**
- Automated daily backups
- Incremental, deduplicated backups
- Encryption support
- Retention policies (7 daily, 5 weekly, 12 monthly)

**Default backup paths:**
- `/home/[username]`: User home directory
- `/etc/nixos`: System configuration

**Excluded:**
- `.cache` directories
- Steam library
- Downloads folder

**Management:**
```bash
# Manual backup
sudo restic -r /backup/restic-repo backup /home/[username]

# Check backup status
sudo systemctl status restic-backups-localbackup

# List snapshots
sudo restic -r /backup/restic-repo snapshots
```

**Configuration**: `configuration.nix`

## System Services

### Automatic Garbage Collection

**Features:**
- Daily automatic cleanup
- Removes system generations older than 90 days
- Store optimization
- Freed space reporting

**Manual cleanup:**
```bash
recycle                           # Clean generations older than 7 days
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

**Interactive update functions:**
```bash
rig-up          # Update + test + prompt to switch (Rig)
hack-up         # Update + test + prompt to switch (Hack)
guard-up        # Update + test + prompt to switch (Guard)
stub-up         # Update + test + prompt to switch (Stub)
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

### CachyOS Kernel

**Features:**
- Gaming-optimized kernel patches
- Better desktop responsiveness
- Lower latency
- Improved throughput

**Configuration**: Enabled via `inputs.cachyos` in `flake.nix`

### System Tuning

**Memory:**
- Shared memory optimization for AI workloads (64GB)
- Swappiness reduced to 10 for better responsiveness

**Download Buffer:**
- 256MB buffer for faster downloads

**Configuration**: Various modules

## Next Steps

- Read [Configuration Guide](CONFIGURATION.md) to customize features
- Check [Customization Guide](CUSTOMIZATION.md) for advanced modifications
- See [Troubleshooting Guide](TROUBLESHOOTING.md) if features aren't working

---

**Note**: All features are designed to work together but can be selectively disabled via feature toggles in `configuration.nix`.
