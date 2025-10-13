# AnomalOS Desktop Configuration

![AnomalOS](modules/desktop/AnomalOS.jpeg)

A comprehensive **modular** NixOS configuration using Nix flakes for a modern desktop system with Hyprland window manager, featuring automated security hardening, theming, AI development tools, and **optional YubiKey and Claude Code support**.

> **⚠️ Important Notice**: This configuration is provided **as-is** for personal use and educational purposes. It is specifically designed for my personal hardware and workflow. While efforts have been made to enable customization, **there are no guarantees this will work on your system without modifications**. You are free to adopt the entire configuration or pick and choose components that suit your needs. This is entirely **FOSS (Free and Open Source Software)**.

## 📚 Documentation

For comprehensive documentation, see the [docs/](docs/) directory:
- [Installation Guide](docs/INSTALLATION.md)
- [Configuration Options](docs/CONFIGURATION.md)
- [Features & Components](docs/FEATURES.md)
- [Customization Guide](docs/CUSTOMIZATION.md)
- [Secret Management](docs/SECRETS.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## 🖥️ System Overview

This configuration targets **x86_64 desktop systems**, providing:

- **OS**: NixOS (unstable channel) with CachyOS kernel
- **Window Manager**: Hyprland (basic configuration, customizable)
- **Display Manager**: SDDM with optional YubiKey U2F authentication
- **Shell**: Fish with Starship prompt
- **Editor**: VS Codium with GitHub Copilot support
- **Theme**: Purple Colony dark theme with consistent styling via Stylix
- **Security**: Hardened with optional YubiKey U2F for login, sudo, and polkit
- **AI Tools**: Optional Ollama + Open WebUI for local AI assistance

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
- **YubiKey** (optional, only needed for Rig/Guard configurations)

### Installation

```bash
# Clone this repository
git clone https://github.com/weegs710/AnomalOS.git ~/dotfiles
cd ~/dotfiles

# Generate hardware configuration for your system
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix

# Test your chosen configuration (IMPORTANT!)
sudo nixos-rebuild test --flake .#Rig  # or Hack, Guard, Stub

# If test succeeds, apply the configuration
sudo nixos-rebuild switch --flake .#Rig

# Reboot
sudo reboot
```

**📖 For detailed installation instructions, see [docs/INSTALLATION.md](docs/INSTALLATION.md)**

## 🔧 System Management

Quick rebuild commands are available as shell aliases:

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

# Interactive update functions
rig-up         # Update flake + test Rig + prompt to switch
hack-up        # Update flake + test Hack + prompt to switch
guard-up       # Update flake + test Guard + prompt to switch
stub-up        # Update flake + test Stub + prompt to switch
```

## 🎨 Key Features

### 🔒 Security
- YubiKey U2F authentication (optional)
- **Agenix** for encrypted secret management
- Suricata IDS for network monitoring
- Hardened firewall with nftables
- Kernel hardening and SSH hardening
- Secure PAM configuration

### 🎨 Desktop Environment
- **Hyprland** compositor
- **Waybar** status bar
- **Stylix** theming with Purple Colony color scheme
- **SDDM** display manager with theme integration

### 🤖 AI Development Tools
- **Claude Code** with enhanced project management (`cc` command) - optional
- **Ollama + Open WebUI** for local AI assistance - optional
  - Commands: `klank`, `klank-cli`, `ai`, `ai-cli`, `ai-web`
  - ROCm support for AMD GPUs
  - Custom NixOS expert model

### 🛠️ Development
- VSCodium with GitHub Copilot support
- Fish shell with intelligent autocompletions
- Development toolchains: Node.js, Python, Rust, Nix
- Language servers: nil (Nix), hyprls (Hyprland)
- Git with custom aliases and workflows
- Kitty GPU-accelerated terminal

### 🎮 Gaming & Media
- Steam with Proton and hardware compatibility
- Lutris, PPSSPP, DeSmuME emulators
- Pipewire audio system
- AMD/Nvidia hybrid GPU support
- Bluetooth stack with bluetui interface

### 📦 Package Management
- Nix Flakes for reproducible configuration
- Home Manager for user-space management
- Flatpak for sandboxed applications
- Cachix binary caches
- Restic automated backups

## 🏗️ Modular Architecture

The configuration is organized into logical modules:

```
dotfiles/
├── flake.nix                    # Main flake definition
├── configuration.nix            # System configuration and feature toggles
├── home.nix                     # Home Manager user configuration
├── hardware-configuration.nix   # Hardware-specific settings (generated)
├── modules/
│   ├── options.nix             # Configuration schema
│   ├── core/                   # Essential system components
│   ├── security/               # Security features and YubiKey
│   ├── desktop/                # Desktop environment
│   ├── development/            # Development tools and AI
│   └── gaming/                 # Gaming support
├── docs/                       # Comprehensive documentation
└── assets/                     # Assets (wallpapers, configs)
```

## 🔧 Customization

Edit `configuration.nix` to customize:

```nix
mySystem = {
  hostName = "your-hostname";
  user = {
    name = "your-username";
    description = "Your Name";
  };

  features = {
    desktop = true;
    security = true;
    development = true;
    gaming = true;
    yubikey = false;        # Toggle YubiKey support
    claudeCode = false;     # Toggle Claude Code
    aiAssistant = false;    # Toggle Ollama + Open WebUI
  };

  hardware = {
    amd = true;
    nvidia = false;
    bluetooth = true;
    steam = true;
  };
};
```

**📖 For detailed customization options, see [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md)**

## 📊 System Requirements

**Target Hardware:**
- AMD/Intel CPU with integrated graphics
- Nvidia GPU (optional/hybrid)
- Bluetooth 5.0+
- NVMe SSD recommended

**Minimum Requirements:**
- 8GB RAM (16GB+ recommended)
- 50GB storage (100GB+ recommended for development)
- UEFI boot support
- Internet connection for initial build

## 🤝 Contributing

This configuration is designed to be easily forkable and customizable:

1. Fork the repository
2. Customize `configuration.nix` for your needs
3. Modify modules as needed
4. Test thoroughly with `sudo nixos-rebuild test`
5. Share improvements via pull requests

## 📄 License

This configuration is **Free and Open Source Software (FOSS)** provided as-is for educational and personal use. Feel free to adapt it for your own systems, use it whole, or take pieces that work for you. No warranties or guarantees are provided.

## 🔗 Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Repository Issues](https://github.com/weegs710/AnomalOS/issues)

---

**Perfect for both new and experienced NixOS users!** Choose your configuration based on your hardware and preferences, then enjoy a fully-configured modern desktop system with optional advanced features. 🚀
