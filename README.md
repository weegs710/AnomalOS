# AnomalOS Desktop Configuration

A modular NixOS configuration using Nix flakes for a desktop system with Hyprland window manager, featuring security hardening, theming, development tools, and optional YubiKey and Claude Code support.

> **Important Notice**: This configuration is provided as-is for personal use and educational purposes. It is specifically designed for my personal hardware and workflow. While efforts have been made to enable customization, there are no guarantees this will work on your system without modifications. You are free to adopt the entire configuration or pick and choose components that suit your needs. This is entirely FOSS (Free and Open Source Software).

## Documentation

For documentation, see the [docs/](docs/) directory:
- [Installation Guide](docs/INSTALLATION.md)
- [Configuration Options](docs/CONFIGURATION.md)
- [Features & Components](docs/FEATURES.md)
- [Customization Guide](docs/CUSTOMIZATION.md)
- [Secret Management](docs/SECRETS.md)
- [ZFS Snapshots & Recovery](docs/BACKUP.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## System Overview

This configuration targets x86_64 desktop systems, providing:

- **OS**: NixOS (unstable channel) with Linux kernel 6.18+ (xanmod)
- **Filesystem**: ZFS with dual-drive setup (system + games)
- **Window Manager**: Hyprland (modular configuration)
- **Display Manager**: Ly with YubiKey U2F authentication
- **Shell**: Fish with Oh My Posh prompt (high contrast base16 colors)
- **Editor**: Zed with language server support
- **Theme**: Noctalia shell UI with dynamic theming via matugen, SpaceMono Nerd Font
- **Security**: Hardened with YubiKey U2F for login, sudo, and polkit

## System Configuration

This flake provides the **Rig** configuration - a NixOS system with:

- **YubiKey Security**: Hardware authentication for login, sudo, and polkit
- **Claude Code**: AI-assisted development
- **Full Feature Set**: All gaming, development, desktop, and media features enabled

## Quick Start

### Prerequisites
- Fresh NixOS installation (any x86_64 machine with internet connection)
- Root or sudo access
- YubiKey (required for hardware authentication)

### Installation

```bash
# Clone this repository (GitHub)
git clone https://github.com/weegs710/AnomalOS.git ~/dotfiles
cd ~/dotfiles

# Or clone from Codeberg
git clone https://codeberg.org/weegs710/AnomalOS.git ~/dotfiles
cd ~/dotfiles

# Generate hardware configuration for your system
# NOTE: This config uses ZFS - see docs/INSTALLATION.md for ZFS-specific setup
sudo nixos-generate-config --show-hardware-config > hardware-configuration-zfs.nix

# Test the configuration (IMPORTANT!)
sudo nixos-rebuild test --flake .#nixosConfigurations.Rig

# If test succeeds, apply the configuration
sudo nixos-rebuild switch --flake .#nixosConfigurations.Rig

# Reboot
sudo reboot
```

For detailed installation instructions, see [docs/INSTALLATION.md](docs/INSTALLATION.md)

## System Management

After initial installation, use `nh` (Nix Helper) for rebuilds:

```bash
# Test configuration (safe, temporary)
nrt-rig        # Test Rig configuration (uses nh)

# Switch configuration (permanent)
nrs-rig        # Switch to Rig configuration (uses nh)

# Interactive update function
rig-up         # Update flake + test Rig + prompt to switch
```

## Key Features

### Security
- YubiKey U2F authentication (optional)
- Agenix for encrypted secret management
- Suricata IDS for network monitoring
- Hardened firewall with nftables
- Kernel hardening and SSH hardening
- Secure PAM configuration

### Desktop Environment
- Hyprland compositor with modular configuration
- Noctalia shell UI with dynamic theming (matugen + adw-gtk3)
- SDDM display manager with theme integration
- Superfile TUI file manager
- Mission Center system monitor (GTK4/Libadwaita)
- LACT AMD GPU management and monitoring

### Development Tools
- Claude Code with project management (`cc` command)
- Zed editor with language server support
- Fish shell with autocompletions
- Development toolchains: Node.js, Python, Rust, Nix
- Language servers: nixd (Nix), hyprls (Hyprland)
- Git with custom aliases and workflows
- Ghostty GPU-accelerated terminal emulator

### Gaming & Media
- Steam with Proton, hardware compatibility, and Decky Loader plugin system
- MangoHud performance overlay with 5 preset levels (Steam Deck-style)
- PPSSPP, DeSmuME, Ryujinx emulators
- RetroArch with automated playlist generation (NES, SNES, N64, GBA, etc.)
- MPD (Music Player Daemon) with Euphonica GTK4 client for music playback
- Beets music library manager with declarative configuration
- Pipewire audio system
- AMD GPU support with Mesa drivers and LACT control tool
- Bluetooth stack with Blueman management interface

### Package Management
- Nix Flakes for reproducible configuration
- Home Manager for user-space management
- Declarative Flatpak management via nix-flatpak
- Multiple binary caches (cache.nixos.org, nix-community, hyprland, ezkea)
- Automated ZFS snapshots with sanoid (hourly, daily, weekly, monthly retention)

## Dendritic Architecture

The configuration uses a dendritic flake-parts pattern with **automatic module discovery**. All features are self-contained flake-parts modules that are automatically discovered and imported:

```
dotfiles/
├── flake.nix                         # Main flake definition with flake-parts
├── hardware-configuration-zfs.nix    # ZFS hardware configuration
├── modules/                          # Dendritic module organization
│   ├── hosts/                       # Host configurations
│   │   └── rig.nix                 # Rig system configuration and feature toggles
│   ├── devshell.nix                # Development shell with nh
│   └── nixos-modules/              # All NixOS feature modules (54 modules)
│       ├── options.nix             # Configuration schema (mySystem.*)
│       ├── boot.nix                # Boot configuration
│       ├── networking.nix          # Network configuration
│       ├── users.nix               # User account configuration
│       ├── nix-daemon.nix          # Nix daemon and helper scripts
│       ├── zfs.nix                 # ZFS snapshots and management
│       ├── packages.nix            # Core packages
│       ├── desktop-packages.nix    # Desktop-specific packages
│       ├── desktop-services.nix    # Desktop services
│       ├── fish.nix                # Fish shell configuration
│       ├── oh-my-posh.nix          # Shell prompt configuration
│       ├── ghostty.nix             # Ghostty terminal emulator
│       ├── superfile.nix           # Superfile TUI file manager
│       ├── fastfetch.nix           # System info display
│       ├── btop.nix                # System monitor
│       ├── kdeconnect.nix          # KDE Connect integration
│       ├── flatpak.nix             # Flatpak management
│       ├── xdg.nix                 # XDG configuration
│       ├── xdg-apps.nix            # XDG MIME associations
│       ├── audio.nix               # Audio system configuration
│       ├── creation.nix            # Media creation tools
│       ├── scraping.nix            # Media downloading utilities
│       ├── mpd.nix                 # Music Player Daemon
│       ├── steam.nix               # Steam platform
│       ├── mangohud.nix            # Performance overlay
│       ├── decky.nix               # Decky Loader plugin system
│       ├── gaming-packages.nix     # Gaming packages and emulators
│       ├── secrets.nix             # Agenix secret management
│       ├── dnscrypt.nix            # DNS encryption
│       ├── firewall.nix            # Firewall configuration
│       ├── suricata.nix            # IDS monitoring
│       ├── yubikey.nix             # YubiKey authentication
│       ├── services.nix            # Security services (SSH, polkit)
│       ├── claude-code.nix         # Claude Code AI assistant
│       ├── languages.nix           # Programming language toolchains
│       ├── vm.nix                  # Virtual machine support
│       ├── tools.nix               # Development utilities
│       ├── zed.nix                 # Zed editor
│       ├── tmux.nix                # Terminal multiplexer
│       ├── hyprland-system.nix     # Hyprland system configuration
│       ├── hyprland-config.nix     # Hyprland compositor settings
│       ├── hyprland-keybinds.nix   # Keyboard shortcuts
│       ├── hyprland-rules.nix      # Window rules
│       ├── hyprland-wallpaper.nix  # Wallpaper management
│       ├── noctalia.nix            # Noctalia shell UI
│       ├── noctalia-data/          # Noctalia data files
│       │   ├── _settings.nix      # Shell configuration
│       │   └── gui-settings.json  # GUI settings
│       └── ...                     # Other feature modules
├── docs/                            # Documentation
└── assets/                          # Assets (wallpapers, configs)
```

### Automatic Module Discovery

The configuration uses **flake-parts with automatic module discovery**, eliminating manual import lists:

**How It Works:**

1. **Flake-Parts Wrapper**:
   - Each module is a flake-parts module that exports `flake.nixosModules.<name>`
   - Example structure:
   ```nix
   { inputs, self, ... }:
   {
     flake.nixosModules.steam = { config, lib, pkgs, ... }:
       with lib; {
         config = mkIf config.mySystem.features.gaming {
           # module implementation
         };
       };
   }
   ```

2. **Automatic Discovery**:
   - Host configuration uses `builtins.attrValues self.nixosModules`
   - All modules in `nixos-modules/` are automatically discovered and imported
   - No manual import lists needed anywhere

3. **Module Naming**:
   - Module files define their own `flake.nixosModules.<name>` attribute
   - Data directories (e.g., `noctalia-data/`) contain supporting files
   - Files starting with `_` are data files, not modules

**Adding New Modules:**

To add a new feature module:

```bash
# Create the module file
cat > modules/nixos-modules/lutris.nix << 'EOF'
{ inputs, self, ... }:
{
  flake.nixosModules.lutris = { config, lib, pkgs, ... }:
    with lib; {
      config = mkIf config.mySystem.features.gaming {
        # Lutris implementation
      };
    };
}
EOF

# That's it - it's automatically discovered!
```

This dendritic pattern allows features to be:
- **Added** without touching import lists
- **Removed** by simply deleting the file
- **Modified** independently without affecting other modules
- **Discovered** automatically on every rebuild

## Customization

Edit `modules/hosts/rig.nix` to customize your system configuration:

```nix
mySystem = {
  hostName = "your-hostname";
  user = {
    name = "your-username";
    description = "Your Name";
    extraGroups = ["networkmanager" "wheel"];
  };

  features = {
    desktop = true;
    security = true;
    development = true;
    gaming = true;
    yubikey = true;         # YubiKey hardware authentication
    claudeCode = true;      # Claude Code AI-assisted development
    flatpak = true;         # Declarative Flatpak management
    media = true;           # Media tools and applications
    kdeconnect = true;      # KDE Connect for device integration
    vm = true;              # Virtual machine support
    androidWebcam = true;   # Android as webcam
  };

  hardware = {
    amd = true;             # AMD GPU support
    bluetooth = true;       # Bluetooth hardware
    steam = true;           # Steam gaming platform
  };

  security = {
    dnscrypt = true;        # DNS encryption
  };
};
```

For detailed customization options, see [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md)

## System Requirements

**Target Hardware:**
- AMD/Intel CPU with integrated graphics
- AMD/Nvidia GPU (optional/hybrid)
- Bluetooth 5.0+
- NVMe SSD (required for ZFS)

**Minimum Requirements:**
- 16GB RAM (32GB+ recommended for ZFS ARC caching)
- 100GB storage for system (ZFS pool)
- Separate drive for games (optional zgames pool)
- UEFI boot support
- Internet connection for initial build

**ZFS Configuration:**
This system uses ZFS for the root filesystem with:
- `zroot` pool: System, nix store, cache, and persistent data
- `zgames` pool: Optional dedicated gaming storage (2TB in reference config)
- Automated snapshots via sanoid (hourly, daily, weekly, monthly retention)
- Compression: zstd
- Auto-trim enabled for SSD health

## Contributing

This configuration can be forked and customized:

1. Fork the repository
2. Customize `configuration.nix` for your needs
3. Modify modules as needed
4. Test thoroughly with `sudo nixos-rebuild test --flake .#nixosConfigurations.Rig`
5. Share improvements via pull requests

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

This configuration is provided as-is for educational and personal use. Feel free to adapt it for your own systems, use it whole, or take pieces that work for you.

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [GitHub Repository](https://github.com/weegs710/AnomalOS) | [Codeberg Repository](https://codeberg.org/weegs710/AnomalOS)
