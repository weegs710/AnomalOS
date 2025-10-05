# AnomalOS Desktop Configuration

A comprehensive **modular** NixOS configuration using Nix flakes for a modern desktop system with Hyprland window manager, featuring automated security hardening, theming, and development tools with **optional YubiKey and Claude Code support**.

## 🖥️ System Overview

This configuration targets **x86_64 desktop systems**, providing:

- **OS**: NixOS (unstable channel) with CachyOS kernel
- **Window Manager**: Hyprland (basic configuration, customizable)
- **Display Manager**: SDDM with optional YubiKey U2F authentication
- **Shell**: Fish with Starship prompt
- **Editor**: VS Codium (primary), with full development toolchain
- **Theme**: Sugarplum dark theme with consistent styling via Stylix
- **Security**: Hardened with optional YubiKey U2F for login, sudo, and polkit

## 🎯 Four Simple Configurations

This flake provides **exactly 4 configurations** to cover all common use cases:

| Configuration | YubiKey (Security) | Claude Code (AI/Dev) | Final Mapping |
|---------------|-------------------|---------------------|---------------|
| `Rig` | ✅ | ✅ | Full system (The complete, optimized machine) |
| `Guard` | ✅ | ❌ | Security Focus (Direct defense via YubiKey) |
| `Hack` | ❌ | ✅ | Dev Focus (Raw, untethered programming) |
| `Stub` | ❌ | ❌ | Minimal system (A basic, essential connection) |

## 🚀 Quick Start

### Prerequisites
- **Fresh NixOS installation** (any x86_64 machine with internet connection)
- **Root or sudo access**
- **YubiKey** (optional, only needed for configurations with YubiKey support)

### Step-by-Step Installation

#### Step 1: Prepare Your System
```bash
# Ensure you're in a clean directory
cd ~

# Install git if not already available
nix-shell -p git

# Verify git is working
git --version
```

#### Step 2: Clone and Setup the Configuration
```bash
# Clone this repository
git clone https://github.com/weegs710/AnomalOS.git ~/dotfiles
cd ~/dotfiles

# Verify you're in the right directory
ls -la
# You should see: flake.nix, configuration.nix, home.nix, modules/, etc.
```

#### Step 3: Generate Hardware Configuration
```bash
# IMPORTANT: This overwrites any existing hardware-configuration.nix
# Generate hardware config for your specific system
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix

# Verify the file was created
ls -la hardware-configuration.nix
# File should exist and be larger than 0 bytes
```

#### Step 4: Choose Your Configuration
**Choose ONE configuration based on your needs:**

| Configuration | Choose If You... |
|---------------|------------------|
| `Rig` | Have a YubiKey and want Claude Code |
| `Hack` | Want Claude Code but no YubiKey |
| `Guard` | Have YubiKey but prefer other dev tools |
| `Stub` | Want basic system (no YubiKey or Claude Code) |

#### Step 5: Test Your Configuration (IMPORTANT!)
**Always test before switching to avoid breaking your system:**

```bash
# Replace Rig with your chosen configuration
sudo nixos-rebuild test --flake .#Rig
```

**What to expect during test:**
- Download and build process (can take 10-30 minutes on first run)
- No errors in the final output
- System should remain functional

**If test fails:**
- Check error messages carefully
- Ensure hardware-configuration.nix was generated correctly
- Try different configuration (e.g., Stub)

#### Step 6: Apply Configuration (Only After Successful Test)
```bash
# Only run this if the test in Step 5 completed successfully
sudo nixos-rebuild switch --flake .#Rig
```

#### Step 7: Reboot and Verify
```bash
# Reboot to ensure everything loads correctly
sudo reboot
```

**After reboot, verify:**
- System boots successfully
- Desktop environment loads (Hyprland + Waybar)
- If using YubiKey config: Login requires YubiKey
- If using Claude Code config: `cc` command is available

### What Happens During Installation

1. **Downloads**: NixOS will download all required packages (several GB)
2. **Builds**: System will compile any necessary components
3. **Configuration**: Applies all module settings and creates user environment
4. **Services**: Starts all configured services (Hyprland, audio, etc.)

## 🔧 System Management

This configuration provides powerful aliases and functions for managing your system:

### Quick Rebuild Commands

**Configuration-specific aliases:**
```bash
# Test configurations (safe, temporary)
nrt-rig        # Test Rig configuration
nrt-hack       # Test Hack configuration
nrt-guard      # Test Guard configuration
nrt-stub       # Test Stub configuration

# Switch configurations (permanent)
nrs-rig        # Switch to Rig configuration
nrs-hack       # Switch to Hack configuration
nrs-guard      # Switch to Guard configuration
nrs-stub       # Switch to Stub configuration
```

### Interactive Update Functions

**Safe update-and-rebuild with prompts:**
```bash
rig-up         # Update flake + test Rig + prompt to switch
hack-up        # Update flake + test Hack + prompt to switch
guard-up       # Update flake + test Guard + prompt to switch
stub-up        # Update flake + test Stub + prompt to switch
```

Each `*-up` function:
1. Updates all flake inputs to latest versions
2. Tests the new configuration safely
3. Prompts you to switch only if test succeeds
4. You can decline to keep the old config

### Manual Operations
```bash
update         # Update flake inputs only
nfa            # Archive flake for sharing
recycle        # Clean up old system generations
```

### Configuration-Specific Setup

#### If You Chose YubiKey Configuration:
After successful installation and reboot:
```bash
# Register your YubiKey (do this on first login)
mkdir -p ~/.config/Yubico
pamu2fcfg > ~/.config/Yubico/u2f_keys

# Test YubiKey authentication
sudo echo "Testing YubiKey"  # Should require YubiKey touch
```

#### If You Chose Claude Code Configuration:
After successful installation and reboot:
```bash
# Test Claude Code is available
claude --version

# Launch Claude Code
claude
```

## 📋 Essential Commands

### System Management
| Command | Description |
|---------|-------------|
| `sudo nixos-rebuild switch --flake .#[config]` | Rebuild and switch to configuration |
| `sudo nixos-rebuild test --flake .#[config]` | Test configuration without switching |
| `nix search nixpkgs [package]` | Search for packages |
| `nix flake update` | Update flake inputs |
| `sudo nix-collect-garbage -d` | Clean up old system generations |
| `nix flake check` | Validate flake syntax |

**Note**: Replace `[config]` with your chosen configuration (Rig, Stub, etc.)

### AI Development Assistant (Claude Code configurations only)
| Command | Description |
|---------|-------------|
| `claude` | Launch Claude Code AI assistant |
| `fastfetch` | Display system info with custom NixOS logo |

**Note**: Claude Code features depend on having Claude Code installed and configured. The modular setup provides the basic integration - full features may require additional setup.

### Development Workflow

#### System Configuration
1. Make configuration changes to files in `~/dotfiles`
2. Test: `sudo nixos-rebuild test --flake .#[your-config]`
3. Apply: `sudo nixos-rebuild switch --flake .#[your-config]` (if tests pass)
4. For updates: `nix flake update` then test and apply

#### Claude Code Development (if enabled)
1. **Launch**: `claude` to start Claude Code
2. **Create projects**: Use standard development workflow
3. **Development**: Use editors like Zed for coding

## 🏗️ Modular Architecture

### Core Files

| File | Purpose |
|------|---------|
| `flake.nix` | Main flake definition with 4 system configurations |
| `configuration.nix` | Feature toggles and basic system options |
| `home.nix` | User-level Home Manager configuration |
| `hardware-configuration.nix` | Hardware-specific settings |
| `modules/options.nix` | Global configuration schema and feature toggles |
| `modules/core/` | Essential system components (always enabled) |
| `modules/security/` | Security features and YubiKey integration |
| `modules/desktop/` | Desktop environment and applications |
| `modules/development/` | Development tools and Claude Code |
| `modules/gaming/` | Gaming support and emulators |

### What's Included

#### 🔒 **Security Features** (All configurations)
- **YubiKey U2F**: Integrated for login, sudo, SDDM, and polkit (optional)
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

#### 🎨 **Desktop Environment** (All configurations)
- **Hyprland**: Wayland compositor (basic configuration)
  - Default Hyprland settings (customizable via home.nix)
  - Hyprland utilities included (grim, slurp, wl-clipboard, etc.)
- **Waybar**: Status bar (configured via home-manager)
  - System monitoring capabilities
  - Themed integration
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

#### 🛠️ **Development Tools** (All configurations)
- **Zed**: Primary code editor with extensive language support
- **Claude Code**: Enhanced AI development assistant with (optional):
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

### Personalizing Your System

Edit `configuration.nix` to customize basic settings:

```nix
mySystem = {
  hostName = "your-hostname";        # Change system hostname
  user = {
    name = "your-username";          # Change your username
    description = "Your Name";       # Change user description
  };

  # Hardware features (adjust for your system)
  hardware = {
    amd = true;                      # Set to false for Intel/NVIDIA only
    nvidia = false;                  # Set to true if you have NVIDIA GPU
    bluetooth = true;                # Set to false if no Bluetooth needed
    steam = true;                    # Set to false if not gaming
  };
};
```

### Advanced Customization

Want to create your own feature combination? Copy one of the configurations in `flake.nix` and modify the features:

```nix
mySystem.features = {
  desktop = true;                    # Keep desktop environment
  security = true;                   # Keep security features
  development = true;                # Keep development tools
  gaming = false;                    # Disable gaming if not needed
  yubikey = false;                   # Your choice
  claudeCode = true;                 # Your choice
};
```

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

Hyprland is enabled in the system configuration at `modules/desktop/hyprland.nix`, but detailed Hyprland settings (keybindings, animations, etc.) would need to be added to `home.nix`:

- **System-level**: `modules/desktop/hyprland.nix` enables Hyprland and installs utilities
- **User-level**: Add `wayland.windowManager.hyprland.settings` to `home.nix` for custom configuration
- **Window rules**: Configure in `home.nix` under `windowrulev2` array
- **Keybindings**: Configure in `home.nix` under `bind`, `bindm`, `bindle` sections

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

1. **Change color scheme**: Modify `modules/desktop/stylix.nix` or replace with another base16 theme
2. **Update wallpaper**: Replace `modules/desktop/monster.jpg` and update reference in stylix configuration
3. **Font changes**: Modify font selections in the Stylix configuration

## 🔐 YubiKey Setup (If Enabled)

If you chose `Rig` or `Guard` configuration:

1. **Register your YubiKey:**
   ```bash
   mkdir -p ~/.config/Yubico
   pamu2fcfg > ~/.config/Yubico/u2f_keys
   ```

2. **Test authentication:**
   ```bash
   sudo echo "YubiKey working!"  # Should prompt for YubiKey touch
   ```

3. **Auto-login behavior:**
   - System automatically logs you in when your registered YubiKey is present
   - Removes auto-login when YubiKey is unplugged
   - Check logs: `sudo journalctl -u yubikey-autologin-init`

### Network Security
- **Firewall**: nftables with restrictive default policies
- **SSH**: Hardened SSH configuration
- **NetworkManager**: Secure network management

## 🤖 Claude Code Features (If Enabled)

If you chose `Rig` or `Hack` configuration:

### Available Commands
```bash
cc                     # Interactive project menu
cc [project]           # Open specific project directly
cc list                # List all available projects
cc new [name]          # Create new project with templates
cc status              # Show Claude Code system status
```

### Enhanced Development Features
- **Global Project Management**: Intelligent navigation across development projects
- **AI Development Assistant**: Advanced workflows and automation
- **Specialized Subagents**: Validation, documentation, NixOS configuration assistance
- **MCP Integration**: Model Context Protocol server support

## 📊 System Specifications

**Target Hardware:**
- AMD/Intel CPU with integrated graphics
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
sudo nix-collect-garbage -d
nix flake update
sudo nixos-rebuild test --flake .#Rig  # or your chosen config
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
3. `nixos-rebuild switch --flake /mnt/path/to/dotfiles#Rig`

## 🤝 Contributing

This configuration is designed to be easily forkable and customizable:

1. **Fork the repository**
2. **Customize** `configuration.nix` for your needs
3. **Add/modify modules** in the `modules/` directory
4. **Test thoroughly** with `sudo nixos-rebuild test`
5. **Share your improvements** via pull requests

## 📄 License

This configuration is provided as-is for educational and personal use. Adapt freely for your own systems.

---

**Perfect for both new and experienced NixOS users!** Choose your configuration based on your hardware and preferences, then enjoy a fully-configured modern desktop system with optional advanced features. 🚀
