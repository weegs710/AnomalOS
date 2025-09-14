# NixOS Desktop Configuration

A comprehensive NixOS configuration using Nix flakes for a modern desktop system with Hyprland window manager, featuring automated security hardening, theming, and development tools.

## 🖥️ System Overview

This configuration targets the **HX99G** desktop system, providing:

- **OS**: NixOS (unstable channel)
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
   git clone <repository-url> ~/dotfiles
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
| `cc` | Launch Claude Code AI development assistant |

**First run:** Follow setup prompts, then run init command to initialize context.

### Development Workflow
1. Make configuration changes
2. Test: `nrt`
3. Apply: `nrs` (if tests pass)
4. For updates: `update-all-test` → `update-all`

## 🏗️ Architecture

### Core Files

| File | Purpose |
|------|---------|
| `flake.nix` | Main flake definition with inputs and system configuration |
| `configuration.nix` | System-level NixOS configuration |
| `home.nix` | User-level Home Manager configuration |
| `hardware-configuration.nix` | Hardware-specific settings |
| `sugarplum.yaml` | Custom Stylix theme configuration |

### System Features

#### 🔒 Security & Authentication
- **YubiKey U2F**: Integrated for login, sudo, SDDM, and polkit
- **Firewall**: nftables with minimal open ports
- **PAM Configuration**: Hardened authentication stack
- **Polkit**: Secure privilege escalation

#### 🎨 Desktop Environment
- **Hyprland**: Wayland compositor with custom configuration
  - Master layout with custom animations
  - No window borders for clean aesthetics
  - Custom keybindings and workspace management
- **SDDM**: Display manager with theme integration
- **Stylix**: Consistent theming across all applications
- **Sugarplum Theme**: Dark color scheme with carefully chosen palette

#### 🔊 Media & Hardware
- **Pipewire**: Modern audio system with low-latency support
- **AMD/Nvidia**: Hybrid GPU support with proper drivers
- **Bluetooth**: Full Bluetooth stack
- **Steam**: Gaming support with hardware compatibility

#### 🛠️ Development Tools
- **Zed**: Primary code editor with extensive language support
- **Claude Code**: AI-powered development assistant with system integration
- **Kitty**: GPU-accelerated terminal emulator
- **Fish Shell**: Modern shell with intelligent autocompletions
- **Git**: Version control with custom aliases
- **Nerd Fonts**: Complete font collection for development

#### 📦 Package Management
- **Nix Flakes**: Reproducible system configuration
- **Home Manager**: User-space package and configuration management
- **Flatpak**: Sandboxed application support
- **Cachix**: Binary cache for faster builds

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

**Minimum Requirements:**
- 8GB RAM (16GB+ recommended)
- 20GB storage (50GB+ recommended for development)
- UEFI boot support
- Internet connection for initial build

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