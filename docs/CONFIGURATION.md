# Configuration Guide

This guide explains the configuration options available in AnomalOS and how to customize them for your needs.

> **Note**: This configuration is designed for my personal use. Customization options are provided, but may require adjustments for your specific hardware and preferences.

## Configuration Structure

AnomalOS uses a dendritic flake-parts structure with **automatic module discovery**:

```
modules/hosts/rig.nix      # Host configuration file
├── mySystem              # System-level settings
│   ├── hostName          # System hostname
│   ├── user              # User account settings
│   ├── features          # Feature toggles
│   ├── hardware          # Hardware capabilities
│   └── security          # Security settings
├── home-manager          # User environment settings
└── nixosModules discovery # Automatic module discovery via builtins.attrValues
```

### Automatic Module Discovery

The configuration uses **flake-parts** with automatic discovery of all modules in `modules/nixos-modules/`. This means:

- **No manual import lists** - modules are discovered via `builtins.attrValues self.nixosModules`
- **Add modules by creating files** - automatically picked up on next rebuild
- **Remove modules by deleting files** - automatically removed on next rebuild
- **Each module is self-contained** - defines its own `flake.nixosModules.<name>` attribute

**Module Structure:**
```nix
{ inputs, self, ... }:
{
  flake.nixosModules.myfeature = { config, lib, pkgs, ... }:
    with lib; {
      config = mkIf config.mySystem.features.myfeature {
        # Feature implementation
      };
    };
}
```

**Data Files:**
- Subdirectories like `noctalia-data/` contain supporting data files
- Files starting with `_` (e.g., `_settings.nix`) are data files, not modules

## Core Configuration Options

### System Settings

Located in the `mySystem` section of `modules/hosts/rig.nix`:

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

- **desktop**: Enables Hyprland compositor, Noctalia shell UI, Ly display manager, Superfile TUI file manager
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
- System monitoring with btop++ and LACT GPU control

## Module Configuration

### Core Modules

Located in `modules/nixos-modules/`:

- **boot.nix**: Boot loader configuration, kernel parameters, kernel hardening
- **networking.nix**: NetworkManager, firewall basics, hostname
- **nix-daemon.nix**: Nix settings, garbage collection, shell aliases, update scripts
- **users.nix**: User account creation and group membership
- **zfs.nix**: Automated ZFS snapshot management with sanoid
- **services.nix**: System services configuration including SSH hardening

### Security Modules

Located in `modules/nixos-modules/`:

- **firewall.nix**: nftables configuration, custom gaming ports (23243-23262), SSH on port 2222
- **suricata.nix**: Intrusion detection system, network monitoring
- **dnscrypt.nix**: DNSCrypt-Proxy for encrypted DNS
- **yubikey.nix**: YubiKey U2F authentication, auto-login, polkit integration

**Note**: Kernel hardening and SSH hardening are configured in boot.nix and services.nix respectively.

**Security Configuration Options:**

Edit `modules/nixos-modules/firewall.nix` to adjust ports:
```nix
# Open additional TCP ports
networking.firewall.allowedTCPPorts = [ 2222 ];

# Open custom port ranges
networking.firewall.allowedTCPPortRanges = [
  { from = 23243; to = 23262; }  # Divinity Original Sin 2
];
```

### Desktop Modules

Located in `modules/nixos-modules/`:

- **hyprland-system.nix**: Hyprland compositor system-level configuration (enables Hyprland, XDG portals, PAM)
- **hyprland-config.nix**: Hyprland settings (monitor, env, animations, workspace definitions)
- **hyprland-keybinds.nix**: All keybindings and submap resize mode
- **hyprland-rules.nix**: Window rules (workspace routing, opacity, float)
- **hyprland-wallpaper.nix**: swww service and wallpaper systemd services
- **noctalia.nix**: Noctalia shell UI service configuration
- **noctalia-data/_settings.nix**: Declarative GUI settings (launcher, bar, appearance, wallpaper)
- **mpd.nix**: MPD (Music Player Daemon) service configuration
- **creation.nix**: Media creation tools (GIMP, OBS, Video2x)
- **desktop-packages.nix**: Desktop applications (Anki, Vesktop, Okular, Qview, etc.)
- **helium.nix**: Helium web browser with Widevine CDM support
- **superfile.nix**: Superfile TUI file manager configuration
- **btop.nix**: btop++ system monitor configuration

**Theme Customization:**

Noctalia theming is managed in `modules/nixos-modules/noctalia-data/settings.nix`:
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
- Configuration: `modules/nixos-modules/noctalia-data/settings.nix` (wallpaper section)

### Development Modules

Located in `modules/nixos-modules/`:

- **zed.nix**: Zed editor with language server support
- **tmux.nix**: tmux terminal multiplexer configuration
- **languages.nix**: Node.js, Python3, Rust, development toolchains, language servers (nixd, nil, hyprls)
- **claude-code.nix**: Claude Code installation, integration, and project management
- **scraping.nix**: Beets music manager, yt-dlp, scrapem/scrapev download commands

**Claude Code Configuration:**

Managed by `modules/nixos-modules/claude-code.nix`:
- Pre-approved commands for autonomous operation
- MCP server integration
- Global project management via `cc` command
- Custom slash commands

### Gaming Modules

Located in `modules/nixos-modules/`:

- **steam.nix**: Steam with Proton, hardware compatibility
- **decky.nix**: Decky Loader Steam plugin system
- **mangohud.nix**: MangoHud performance overlay with presets
- **gaming-packages.nix**: RetroArch cores, PPSSPP, DeSmuME, Ryujinx emulators

## Home Manager Configuration

User-level configuration managed in `modules/nixos-modules/` (integrated with home-manager):

### Shell Configuration

Configured in `modules/nixos-modules/`:

```nix
# Fish shell - modules/nixos-modules/fish.nix
programs.fish = {
  enable = true;
  # Custom functions, aliases, plugins
};

# Oh My Posh prompt - modules/nixos-modules/oh-my-posh.nix
programs.oh-my-posh = {
  enable = true;
  # JSON schema configuration with git integration
};
```

### Terminal Configuration

Configured in `modules/nixos-modules/ghostty.nix`:

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

Defined in `modules/nixos-modules/nix-daemon.nix`:

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
    ./modules/hosts/rig.nix
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

Thanks to flake-parts automatic module discovery, adding new modules is simple - just create a `.nix` file in the appropriate `modules/nixos-modules/` subdirectory:

**Example: Adding Lutris Gaming Support**

1. Create the module file:
```bash
touch modules/nixos-modules/lutris.nix
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
mkdir -p modules/nixos-modules/lutris
touch modules/nixos-modules/lutris/default.nix
touch modules/nixos-modules/lutris/_config.nix
touch modules/nixos-modules/lutris/_settings.nix
```

Structure:
```
modules/nixos-modules/lutris/
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
- No need to update `modules/hosts/rig.nix` or any import lists
- Module is active when appropriate feature flag is enabled

### Adding Custom Packages

System-wide packages in `modules/hosts/rig.nix`:
```nix
environment.systemPackages = with pkgs; [
  your-package-here
];
```

User packages in `modules/nixos-modules/packages.nix`:
```nix
home.packages = with pkgs; [
  your-package-here
];
```

### Custom Services

System services in `modules/hosts/rig.nix`:
```nix
services.your-service = {
  enable = true;
  # configuration...
};
```

User services in home-manager modules (within `modules/nixos-modules/`):
```nix
home-manager.users.${config.mySystem.user.name} = {
  systemd.user.services.your-service = {
    # service configuration...
  };
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
