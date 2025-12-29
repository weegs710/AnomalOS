# Configuration Guide

This guide explains the configuration options available in AnomalOS and how to customize them for your needs.

> **Note**: This configuration is designed for my personal use. Customization options are provided, but may require adjustments for your specific hardware and preferences.

## Configuration Structure

AnomalOS uses a modular configuration structure defined in `configuration.nix`:

```
configuration.nix          # Main configuration file
├── mySystem              # System-level settings
│   ├── hostName          # System hostname
│   ├── user              # User account settings
│   ├── features          # Feature toggles
│   └── hardware          # Hardware capabilities
├── home-manager          # User environment settings
└── services.restic       # Backup configuration
```

## Core Configuration Options

### System Settings

Located in the `mySystem` section of `configuration.nix`:

```nix
mySystem = {
  hostName = "HX99G";           # Your system's network name

  user = {
    name = "weegs";             # Primary username
    description = "weegs";      # User full name/description
    extraGroups = [             # Additional user groups
      "networkmanager"
      "wheel"
    ];
  };

  timeZone = "America/New_York"; # System timezone (from options.nix)
};
```

**Configuration Tips:**
- `hostName`: Choose a unique name for your system on the network
- `user.name`: Must match your desired login username
- `user.extraGroups`: "wheel" required for sudo access
- `timeZone`: Use standard IANA timezone names

### Feature Toggles

Control which features are enabled in your configuration:

```nix
mySystem.features = {
  desktop = true;        # Desktop environment (Hyprland)
  security = true;       # Security hardening features
  yubikey = true;        # YubiKey U2F authentication
  claudeCode = true;     # Claude Code development assistant
  development = true;    # Development tools and languages
  gaming = true;         # Gaming support (Steam, emulators)
  flatpak = true;        # Declarative Flatpak management
  media = true;          # Media tools and applications
  kdeconnect = true;     # KDE Connect integration
};
```

**Feature Descriptions:**

- **desktop**: Enables Hyprland compositor, Waybar, SDDM, Stylix theming
- **security**: Enables firewall, Suricata IDS, kernel hardening, SSH hardening, DNSCrypt-Proxy
- **yubikey**: Enables YubiKey U2F for login, sudo, and polkit
- **claudeCode**: Installs Claude Code with enhanced project management
- **development**: Installs editors, language servers, development toolchains
- **gaming**: Installs Steam, anime game launchers, emulators, gaming optimizations
- **flatpak**: Enables declarative Flatpak management via nix-flatpak
- **media**: Enables media tools, applications, and Beets music manager
- **kdeconnect**: Enables KDE Connect for device integration

### Hardware Configuration

Specify your hardware capabilities:

```nix
mySystem.hardware = {
  amd = true;           # AMD GPU support (enables ROCm)
  nvidia = false;       # NVIDIA GPU support
  bluetooth = true;     # Bluetooth hardware support
  steam = true;         # Steam hardware compatibility layers
};
```

**Hardware Options:**

- **amd**: Enables AMD GPU drivers and Mesa acceleration
- **bluetooth**: Enables Bluetooth stack with bluetui interface
- **steam**: Enables Steam with Proton, Gamescope, hardware compatibility

## System Configuration

AnomalOS provides the **Rig** configuration - a complete, full-featured system:

### Rig Configuration

```nix
# All features enabled
features = {
  desktop = true;
  security = true;
  yubikey = true;        # YubiKey hardware authentication
  claudeCode = true;     # Claude Code AI development assistant
  development = true;
  gaming = true;
  flatpak = true;        # Declarative Flatpak management
  media = true;          # Media tools and applications
  kdeconnect = true;     # KDE Connect integration
};
```

This configuration provides:
- Full desktop environment with Hyprland
- YubiKey hardware authentication for login, sudo, and polkit
- Claude Code for AI-assisted development
- Complete development toolchain
- Gaming support with Steam, anime game launchers, and emulators
- Music system with MPD, Euphonica client, and Beets library manager

## Module Configuration

### Core Modules

Located in `modules/system/core/`:

- **boot.nix**: Boot loader configuration, kernel parameters
- **networking.nix**: NetworkManager, firewall basics, hostname
- **nix.nix**: Nix settings, garbage collection, shell aliases, update scripts
- **users.nix**: User account creation and group membership
- **zfs-snapshots.nix**: Automated ZFS snapshot management with sanoid

### Security Modules

Located in `modules/system/security/`:

- **firewall.nix**: nftables configuration, custom gaming ports (23243-23262), SSH on port 2222
- **hardening.nix**: Kernel sysctl parameters, SSH hardening, PAM configuration
- **suricata.nix**: Intrusion detection system, network monitoring
- **yubikey.nix**: YubiKey U2F authentication, auto-login, polkit integration

**Security Configuration Options:**

Edit `modules/system/security/firewall.nix` to adjust ports:
```nix
# Open additional TCP ports
networking.firewall.allowedTCPPorts = [ 2222 ];

# Open custom port ranges
networking.firewall.allowedTCPPortRanges = [
  { from = 23243; to = 23262; }  # Divinity Original Sin 2
];
```

### Desktop Modules

Located in `modules/system/desktop/`:

- **hyprland.nix**: Hyprland compositor system-level configuration (enables Hyprland, XDG portals, PAM)
- **mpd.nix**: MPD (Music Player Daemon) service configuration
- **media.nix**: Applications (GIMP, Anki, Vesktop, OBS), media tools
- **stylix.nix**: Theme configuration (Axion custom base16 color scheme)

**Theme Customization:**

Edit `modules/system/desktop/stylix.nix` to change the theme:
```nix
stylix.base16Scheme = ./axion.yaml;  # Custom Axion theme
# Or use a different base16 theme file
```

The Axion theme file (`axion.yaml`) contains custom purple/magenta color palette.

**Wallpaper Management:**
- Add images to `~/.local/share/wallpapers/`
- Wallpapers rotate automatically every 15 minutes
- Systemd service manages wallpaper rotation
- Configuration: `modules/home-manager/desktop/hyprland/wallpaper.nix`

### Development Modules

Located in `modules/system/development/`:

- **editors.nix**: Zed editor with language servers (nixd, nil, hyprls), tmux
- **languages.nix**: Node.js, Python3, Rust, development toolchains
- **claude-code.nix**: Claude Code installation and integration
- **media.nix**: Beets music manager, yt-dlp, scrapem/scrapev download commands

**Claude Code Configuration:**

Managed by `modules/claude-code-enhanced/default.nix`:
- Pre-approved commands for autonomous operation
- MCP server integration
- Global project management via `cc` command
- Custom slash commands

### Gaming Modules

Located in `modules/system/gaming/`:

- **steam.nix**: Steam with Proton, hardware compatibility
- **default.nix**: Lutris, PPSSPP, DeSmuME emulators

## Home Manager Configuration

User-level configuration managed in `modules/home-manager/`:

### Shell Configuration

Configured in `modules/home-manager/development/`:

```nix
# Fish shell - modules/home-manager/development/fish.nix
programs.fish = {
  enable = true;
  # Custom functions, aliases, plugins
};

# Oh My Posh prompt - modules/home-manager/development/oh-my-posh.nix
programs.oh-my-posh = {
  enable = true;
  # JSON schema configuration with git integration
};
```

### Terminal Configuration

Configured in `modules/home-manager/desktop/ghostty.nix`:

```nix
programs.ghostty = {
  enable = true;
  settings = {
    font-family = "Terminess Nerd Font";  # From Stylix
    font-size = 13;  # Configured in Stylix
    theme = "Axion";  # Uses Stylix theme
    scroll-to-bottom = "keystroke";
  };
};
```

### Git Configuration

```nix
programs.git = {
  enable = true;
  userName = "Your Name";
  userEmail = "your.email@example.com";
  # Git aliases and settings
};
```

## Shell Aliases and Functions

Defined in `modules/system/core/nix.nix`:

### Quick Rebuild Aliases

```bash
nrs-rig       # Switch to Rig configuration (uses nh)
nrt-rig       # Test Rig configuration (uses nh)
```

### Update Functions

```bash
rig-up        # Update + test + prompt to switch (Rig)
```

### Utility Aliases

```bash
update        # Update flake inputs
nfa           # Archive flake for sharing
recycle       # Keep last 10 generations, remove older
```

## Advanced Customization

### Creating Custom Configurations

To create your own configuration variant, edit `flake.nix`:

```nix
nixosConfigurations.MyConfig = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {inherit inputs;};
  modules = [
    inputs.stylix.nixosModules.stylix
    ./configuration.nix
    {
      mySystem.features = {
        desktop = true;
        security = true;
        yubikey = false;      # Your custom settings
        claudeCode = true;
        development = true;
        gaming = false;       # Disable gaming
      };
    }
  ];
};
```

### Adding Custom Packages

System-wide packages in `configuration.nix`:
```nix
environment.systemPackages = with pkgs; [
  your-package-here
];
```

User packages in `modules/home-manager/core/packages.nix`:
```nix
home.packages = with pkgs; [
  your-package-here
];
```

### Custom Services

System services in `configuration.nix`:
```nix
services.your-service = {
  enable = true;
  # configuration...
};
```

User services in `home.nix`:
```nix
systemd.user.services.your-service = {
  # service configuration...
};
```

## Configuration Validation

### Check Configuration Syntax

```bash
# Validate flake syntax
nix flake check

# Build configuration without applying
nix build .#nixosConfigurations.Rig.config.system.build.toplevel
```

### Test Changes Safely

```bash
# Always test before switching (uses nh)
nh os test .#nixosConfigurations.Rig

# If successful, then switch (uses nh)
nh os switch .#nixosConfigurations.Rig

# Or use the aliases
nrt-rig       # Test
nrs-rig       # Switch
```

## Next Steps

- Review [Features Guide](FEATURES.md) for detailed feature documentation
- Check [Customization Guide](CUSTOMIZATION.md) for advanced modifications
- See [Troubleshooting Guide](TROUBLESHOOTING.md) if you encounter issues

---

**Remember**: Configuration changes should always be tested before applying permanently. Keep backups of your working configuration.
