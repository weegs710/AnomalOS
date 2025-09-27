# NixOS Desktop Configuration

A comprehensive NixOS configuration using Nix flakes for a modern desktop system with Hyprland window manager, featuring automated security hardening, theming, and development tools.

## 🖥️ System Overview

This configuration targets the **HX99G** desktop system, providing:

- **OS**: NixOS (unstable channel) with CachyOS kernel
- **Window Manager**: Hyprland with custom animations and keybindings
- **Display Manager**: SDDM with YubiKey U2F authentication
- **Shell**: Fish with Starship prompt
- **Editor**: Zed (primary), with full development toolchain
- **Theme**: Sugarplum dark theme with consistent styling via Stylix
- **Security**: Hardened with YubiKey U2F for login, sudo, and polkit

## 🚀 Quick Start

### Prerequisites
- NixOS system
- Git
- YubiKey (optional, for enhanced security features)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/weegs710/nix-install.git ~/dotfiles
   cd ~/dotfiles
   ```

2. **Update hardware configuration:**
   ```bash
   # Generate hardware config for your system
   sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
   ```

3. **Test the configuration:**
   ```bash
   nrt  # Test rebuild without switching
   ```

4. **Apply the configuration:**
   ```bash
   nrs  # Rebuild and switch to new configuration
   ```

## 📋 Essential Commands

### System Management
| Command | Description |
|---------|-------------|
| `nrs` | Rebuild and switch to new NixOS configuration |
| `nrt` | Test new configuration without switching |
| `ns` | Search nixpkgs packages interactively with fzf |
| `update-all` | Update flake inputs and rebuild system |
| `update-all-test` | Update and test rebuild |
| `recycle` | Clean up old system generations (7+ days) |
| `nfa` | Archive flake |

### AI Development Assistant
| Command | Description |
|---------|-------------|
| `cc` | Enhanced Claude Code project launcher with interactive navigation |
| `cc [project]` | Open specific project directly with global optimizations |
| `cc list` | List all available projects |
| `cc new [name]` | Create new project with optimization templates |
| `cc status` | Show Claude Code system status and available features |
| `cc help` | Show complete usage information |
| `ff` | Display system info with custom NixOS logo |

**Enhanced Claude Code Features:**
- **Global Optimization**: Masterclass patterns and autonomous operation across all projects
- **12 Slash Commands**: Including `/primer`, `/analyze`, `/generate`, `/execute`
- **4 Specialized Subagents**: Validation, documentation, NixOS configuration, security
- **Parallel Development**: Multi-approach development with `/prep-parallel`
- **MCP Integration**: Ready for Serena and other Model Context Protocol servers
- **Project Templates**: Rapid setup for new development projects

### Development Workflow

#### System Configuration
1. Make configuration changes
2. Test: `nrt`
3. Apply: `nrs` (if tests pass)
4. For updates: `update-all-test` → `update-all`

#### Claude Code Projects
1. **Navigate**: `cc` to see project menu or `cc [project]` for direct access
2. **Create**: `cc new [name]` for new projects with optimization templates
3. **Develop**: All projects inherit global optimizations and advanced features
4. **Advanced**: Use `/prep-parallel` for complex multi-approach development

**Project Structure:**
```
~/claude-projects/
├── .claude/                    # Global optimization configuration
├── projects/                   # All individual development projects
│   ├── hx99g/                 # NixOS configuration project
│   ├── my-app/                # Example application project
│   └── [other-projects]/      # Additional projects
├── templates/                  # Project templates for rapid setup
├── shared/                     # Shared resources and patterns
└── claude-launcher.sh          # Enhanced cc command script
```

## 🏗️ Architecture

### Core Files

| File | Purpose |
|------|---------|
| `flake.nix` | Main flake definition with inputs and system configuration |
| `configuration.nix` | System-level NixOS configuration |
| `home.nix` | User-level Home Manager configuration |
| `hardware-configuration.nix` | Hardware-specific settings |
| `sugarplum.yaml` | Custom Stylix theme configuration |
| `flake.lock` | Pinned versions of flake inputs |
| `monster.jpg` | Wallpaper image for theme generation |

### System Features

#### 🔒 Security & Authentication
- **YubiKey U2F**: Integrated for login, sudo, SDDM, and polkit
  - Automatic login when registered YubiKey is present
  - Systemd services for dynamic login control
- **Suricata IDS**: Network intrusion detection and prevention
  - Real-time traffic monitoring
  - Alert logging to `/var/log/suricata/`
- **Firewall**: nftables with restrictive policies
  - Custom gaming ports (23243-23262) for Divinity Original Sin 2
  - SSH on non-standard port 2222
- **Kernel Hardening**: Extensive sysctl security parameters
- **SSH Hardening**: Modern ciphers and restricted access
- **PAM Configuration**: Hardened authentication stack
- **Polkit**: Secure privilege escalation

#### 🎨 Desktop Environment
- **Hyprland**: Wayland compositor with custom configuration
  - Master layout with custom animations
  - No window borders for clean aesthetics
  - Custom keybindings and workspace management
- **Waybar**: Custom status bar with system monitoring
  - Temperature, network, audio, and workspace indicators
  - Power controls and application shortcuts
  - Themed with Sugarplum colors
- **SDDM**: Display manager with theme integration
- **Stylix**: Consistent theming across all applications
- **Sugarplum Theme**: Dark color scheme with carefully chosen palette

#### 🔊 Media & Hardware
- **Pipewire**: Modern audio system with low-latency support
- **AMD/Nvidia**: Hybrid GPU support with proper drivers
- **Bluetooth**: Full Bluetooth stack with bluetui interface
- **Steam**: Gaming support with Proton, Gamescope, and hardware compatibility
- **Gaming**: Lutris, PPSSPP, DeSmuME emulators
- **Media**: MPV player, OBS Studio for streaming
- **Productivity**: GIMP, LibreWolf browser, Anki flashcards
- **Communication**: Vesktop (Discord)

#### 🛠️ Development Tools
- **Zed**: Primary code editor with extensive language support
- **Claude Code**: Enhanced AI development assistant with:
  - **Global Project Management**: Intelligent navigation across all development projects
  - **Masterclass Optimizations**: Advanced autonomous operation with pre-approved permissions
  - **Specialized Subagents**: Validation gates, documentation, NixOS config, security audit
  - **Parallel Development**: Multi-approach implementation with comparison analysis
  - **Context Engineering**: PRP (Product Requirements Prompt) framework
  - **MCP Integration**: Model Context Protocol server support (Serena ready)
  - **Development Hooks**: Automated quality gates and lifecycle management
- **Kitty**: GPU-accelerated terminal emulator
- **Fish Shell**: Modern shell with intelligent autocompletions
- **Development Languages**: Node.js, Python3, Rust, Nix
- **Language Servers**: nil (Nix), hyprls (Hyprland)
- **Code Formatting**: alejandra (Nix formatter)
- **Git**: Version control with custom aliases and automated workflows
- **Nerd Fonts**: Complete font collection for development

#### 📦 Package Management
- **Nix Flakes**: Reproducible system configuration
- **Home Manager**: User-space package and configuration management
- **Flatpak**: Sandboxed application support
- **Cachix**: Binary cache for faster builds (nix-community, hyprland)
- **Restic Backups**: Automated daily backups with retention policies
  - Backs up home directory and system configuration
  - 7-day, 5-week, 12-month retention
  - Excludes cache and temporary files

## 🔧 Customization

### Adding Applications

**System-wide packages:**
```nix
# In configuration.nix
environment.systemPackages = with pkgs; [
  your-package-here
];
```

**User packages:**
```nix
# In home.nix
home.packages = with pkgs; [
  your-package-here
];
```

### Modifying Hyprland

All Hyprland configuration is in `home.nix` under `wayland.windowManager.hyprland.settings`:

- **Keybindings**: `bind`, `bindm`, `bindle` sections
- **Window rules**: `windowrulev2` array
- **Startup apps**: `exec-once` array
- **Animations**: `animation` and `bezier` sections

### Adding Services

**System services:**
```nix
# In configuration.nix
services.your-service = {
  enable = true;
  # configuration...
};
```

**User services:**
```nix
# In home.nix under respective program configurations
programs.your-program = {
  enable = true;
  # configuration...
};
```

### Shell Aliases

Add to `environment.shellAliases` in `configuration.nix`:
```nix
environment.shellAliases = {
  your-alias = "your-command";
};
```

## 🎨 Theming

The system uses **Stylix** for consistent theming with the **Sugarplum** color scheme:

- **Base**: Dark polarity with carefully selected accent colors
- **Applications**: Automatic theming for GTK, Qt, terminals, editors
- **Wallpaper**: `monster.jpg` with color extraction for dynamic theming
- **Fonts**: Nerd Fonts with consistent typography across applications

### Customizing the Theme

1. **Change color scheme**: Modify `sugarplum.yaml` or replace with another base16 theme
2. **Update wallpaper**: Replace `monster.jpg` and update reference in `configuration.nix`
3. **Font changes**: Modify font selections in the Stylix configuration

## 🔐 Security Features

### YubiKey Integration
- **Login**: U2F authentication for user sessions
- **Sudo**: Two-factor authentication for privilege escalation
- **SDDM**: Hardware key requirement for display manager
- **Polkit**: Secure authentication for system actions
- **Auto-Login**: Automatic login when registered YubiKey is detected
  - Systemd services monitor YubiKey insertion/removal
  - Validates registered keys against U2F configuration
  - Enables/disables SDDM auto-login dynamically

### Network Security
- **Firewall**: nftables with restrictive default policies
- **SSH**: Hardened SSH configuration
- **NetworkManager**: Secure network management

## 📊 System Specifications

**Target Hardware (HX99G):**
- AMD CPU with integrated graphics
- Nvidia GPU (optional/hybrid)
- Bluetooth 5.0+
- Audio: Pipewire-compatible
- Storage: NVMe SSD recommended
- **Kernel**: CachyOS optimized for gaming performance

**Minimum Requirements:**
- 8GB RAM (16GB+ recommended)
- 50GB storage (100GB+ recommended for development and backups)
- UEFI boot support
- Internet connection for initial build
- Additional storage for Restic backups (recommended)

## 🚨 Troubleshooting

### Common Issues

**Build failures:**
```bash
# Clean and retry
recycle
nix flake update
nrt
```

**Audio not working:**
```bash
# Restart Pipewire
systemctl --user restart pipewire
```

**Display issues:**
```bash
# Check Hyprland logs
journalctl --user -u hyprland
```

**YubiKey not detected:**
```bash
# Check hardware
lsusb | grep Yubikey
systemctl status pcscd
```

### Recovery

If the system becomes unbootable:

1. Boot from NixOS installer
2. Mount your filesystems
3. `nixos-rebuild switch --flake /mnt/path/to/dotfiles#HX99G`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test changes with `nrt`
4. Submit a pull request

## 📄 License

This configuration is provided as-is for educational and personal use. Adapt freely for your own systems.

---

**Note**: This configuration includes security hardening and YubiKey integration. Ensure you have proper backup authentication methods before enabling U2F requirements.
