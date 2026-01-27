# Configuration Guide

This guide explains the configuration options available in AnomalOS and how to customize them for your needs.

> **Note**: This configuration is designed for my personal use. Customization options are provided, but may require adjustments for your specific hardware and preferences.

## Configuration Structure

AnomalOS uses a modular configuration structure with **automatic module discovery**:

```
configuration.nix          # Main configuration file
├── mySystem              # System-level settings
│   ├── hostName          # System hostname
│   ├── user              # User account settings
│   ├── features          # Feature toggles
│   └── hardware          # Hardware capabilities
├── home-manager          # User environment settings
└── import-tree           # Automatic module discovery from features/
```

### Import-Tree Auto-Discovery

The configuration uses **import-tree** to automatically discover and import modules from the `features/` directory. This means:

- **No manual import lists** - modules are discovered automatically
- **Add modules by creating files** - no need to update import statements
- **Rename/move modules freely** - changes are picked up automatically
- **Remove modules by deleting files** - no cleanup needed

**Naming Convention:**
- Files without underscore prefix (e.g., `boot.nix`, `steam.nix`) are **auto-imported**
- Files with underscore prefix (e.g., `_settings.nix`, `_config.nix`) are **excluded** (must be imported manually by parent modules)
- Directories with underscore prefix (e.g., `_claude-code-enhanced/`) are **entirely excluded**

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

- **desktop**: Enables Hyprland compositor, Noctalia shell UI, SDDM, Superfile TUI file manager
- **security**: Enables firewall, Suricata IDS, kernel hardening, SSH hardening, DNSCrypt-Proxy
- **yubikey**: Enables YubiKey U2F for login, sudo, and polkit
- **claudeCode**: Installs Claude Code with project management
- **development**: Installs editors, language servers, development toolchains
- **gaming**: Installs Steam, Decky Loader, MangoHud, emulators
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

- **amd**: Enables AMD GPU drivers, Mesa acceleration, and LACT GPU control
- **bluetooth**: Enables Bluetooth stack with Blueman GTK interface
- **steam**: Enables Steam with Proton, Gamescope, Decky Loader, hardware compatibility

## System Configuration

AnomalOS provides the **Rig** configuration:

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
- Desktop environment with Hyprland and Noctalia shell UI
- YubiKey hardware authentication for login, sudo, and polkit
- Claude Code for AI-assisted development
- Development toolchain (Node.js, Python, Rust, Nix)
- Gaming support with Steam, Decky Loader, MangoHud, and emulators
- Music system with MPD, Euphonica client, and Beets library manager
- System monitoring with Mission Center and LACT GPU control

## Module Configuration

### Core Modules

Located in `features/core/`:

- **boot.nix**: Boot loader configuration, kernel parameters
- **networking.nix**: NetworkManager, firewall basics, hostname
- **nix.nix**: Nix settings, garbage collection, shell aliases, update scripts
- **users.nix**: User account creation and group membership
- **zfs-snapshots.nix**: Automated ZFS snapshot management with sanoid

### Security Modules

Located in `features/security/`:

- **firewall.nix**: nftables configuration, custom gaming ports (23243-23262), SSH on port 2222
- **hardening.nix**: Kernel sysctl parameters, SSH hardening, PAM configuration
- **suricata.nix**: Intrusion detection system, network monitoring
- **yubikey.nix**: YubiKey U2F authentication, auto-login, polkit integration

**Security Configuration Options:**

Edit `features/security/firewall.nix` to adjust ports:
```nix
# Open additional TCP ports
networking.firewall.allowedTCPPorts = [ 2222 ];

# Open custom port ranges
networking.firewall.allowedTCPPortRanges = [
  { from = 23243; to = 23262; }  # Divinity Original Sin 2
];
```

### Desktop Modules

Located in `features/desktop/`:

- **hyprland.nix**: Hyprland compositor system-level configuration (enables Hyprland, XDG portals, PAM)
- **mpd.nix**: MPD (Music Player Daemon) service configuration
- **media.nix**: Applications (GIMP, Anki, Vesktop, OBS), media tools

Located in `features/desktop/`:

- **noctalia/**: Dynamic shell UI with launcher, bar, notifications (settings.nix, default.nix)
- **hyprland/**: User-level Hyprland configuration (config.nix, keybinds.nix, rules.nix, wallpaper.nix)
- **helium.nix**: Helium music browser with Widevine CDM support
- **superfile.nix**: Superfile TUI file manager configuration
- **mission-center.nix**: System monitor configuration

**Theme Customization:**

Noctalia theming is managed in `features/noctalia/settings.nix`:
```nix
# Change matugen color scheme
"theme" = {
  "matugen" = {
    "scheme" = "scheme-fruit-salad";  # Current: Fruit Salad
  };
};

# Change fonts
"fonts" = {
  "family" = "SpaceMono Nerd Font";   # Current font family
};
```

**Wallpaper Management:**
- Add images to `~/.local/share/wallpapers/`
- Wallpapers rotate automatically every 10 minutes via noctalia
- Wave transitions with 5-second duration
- Configuration: `features/noctalia/settings.nix` (wallpaper section)

### Development Modules

Located in `features/development/`:

- **editors.nix**: Zed editor with language servers (nixd, nil, hyprls), tmux
- **languages.nix**: Node.js, Python3, Rust, development toolchains
- **claude-code.nix**: Claude Code installation and integration
- **media.nix**: Beets music manager, yt-dlp, scrapem/scrapev download commands

**Claude Code Configuration:**

Managed by `features/development/claude-code-enhanced/default.nix`:
- Pre-approved commands for autonomous operation
- MCP server integration
- Global project management via `cc` command
- Custom slash commands

### Gaming Modules

Located in `features/gaming/`:

- **steam.nix**: Steam with Proton, hardware compatibility
- **default.nix**: RetroArch cores, PPSSPP, DeSmuME, Ryujinx emulators

## Home Manager Configuration

User-level configuration managed in `features/` (integrated with home-manager):

### Shell Configuration

Configured in `features/editors/`:

```nix
# Fish shell - features/editors/fish.nix
programs.fish = {
  enable = true;
  # Custom functions, aliases, plugins
};

# Oh My Posh prompt - features/editors/oh-my-posh.nix
programs.oh-my-posh = {
  enable = true;
  # JSON schema configuration with git integration
};
```

### Terminal Configuration

Configured in `features/desktop/ghostty.nix`:

```nix
programs.ghostty = {
  enable = true;
  settings = {
    font-family = "SpaceMono Nerd Font Mono";
    font-size = 13;
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

Defined in `features/core/nix.nix`:

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

## Custom Configurations

### Creating Custom Configurations

To create your own configuration variant, edit `flake.nix`:

```nix
nixosConfigurations.MyConfig = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {inherit inputs;};
  modules = [
    # inputs.stylix.nixosModules.stylix  # Disabled, using noctalia
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

### Adding New Modules

Thanks to the import-tree system, adding new modules is simple - just create a `.nix` file in the appropriate `features/` subdirectory:

**Example: Adding Lutris Gaming Support**

1. Create the module file:
```bash
touch features/gaming/lutris.nix
```

2. Write the module (no import statements needed):
```nix
{ config, lib, pkgs, ... }:

with lib; {
  config = mkIf config.mySystem.features.gaming {
    environment.systemPackages = with pkgs; [
      lutris
    ];
  };
}
```

3. Rebuild - the module is automatically discovered:
```bash
nrt-rig  # Test the configuration
```

**Multi-File Modules:**

For complex features, create a directory with `default.nix` and helper files:

```bash
mkdir -p features/gaming/lutris
touch features/gaming/lutris/default.nix
touch features/gaming/lutris/_config.nix
touch features/gaming/lutris/_settings.nix
```

Structure:
```
features/gaming/lutris/
├── default.nix      # Auto-imported (entry point)
├── _config.nix      # Helper (imported by default.nix)
└── _settings.nix    # Helper (imported by default.nix)
```

In `default.nix`:
```nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./_config.nix
    ./_settings.nix
  ];

  config = lib.mkIf config.mySystem.features.gaming {
    # Main module implementation
  };
}
```

**Key Points:**
- Module filename determines if it's auto-imported (no underscore = auto-import)
- Helper files use underscore prefix to exclude from auto-discovery
- No need to update `configuration.nix` or any import lists
- Module is active when appropriate feature flag is enabled

### Adding Custom Packages

System-wide packages in `configuration.nix`:
```nix
environment.systemPackages = with pkgs; [
  your-package-here
];
```

User packages in `features/core/packages.nix`:
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
- Check [Customization Guide](CUSTOMIZATION.md) for modifications
- See [Troubleshooting Guide](TROUBLESHOOTING.md) if you encounter issues

---

**Remember**: Configuration changes should always be tested before applying permanently. Keep backups of your working configuration.
