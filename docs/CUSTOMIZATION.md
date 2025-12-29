# Customization Guide

This guide explains how to customize and extend AnomalOS for your specific needs and preferences.

> **Reminder**: This configuration is designed for my personal setup. While customization is supported, some changes may require additional adjustments for your hardware.

## Table of Contents

- [Basic Customization](#basic-customization)
- [Theme Customization](#theme-customization)
- [Desktop Environment](#desktop-environment)
- [Adding Software](#adding-software)
- [Creating Custom Configurations](#creating-custom-configurations)
- [Service Configuration](#service-configuration)
- [Advanced Customization](#advanced-customization)

## Basic Customization

### User and System Settings

Edit `configuration.nix`:

```nix
mySystem = {
  # Change system hostname
  hostName = "my-computer";

  # Change user settings
  user = {
    name = "myusername";
    description = "My Full Name";
    extraGroups = [
      "networkmanager"  # Network management
      "wheel"           # Sudo access (required)
      "docker"          # Add if using Docker
      "libvirtd"        # Add if using VMs
    ];
  };
};
```

### Feature Toggles

Enable or disable major features:

```nix
mySystem.features = {
  desktop = true;          # Keep desktop
  security = true;         # Keep security features
  yubikey = false;         # Disable YubiKey if you don't have one
  claudeCode = true;       # Keep Claude Code
  development = true;      # Keep dev tools
  gaming = false;          # Disable if not gaming
  flatpak = true;          # Declarative Flatpak management
  media = true;            # Media tools and applications
  kdeconnect = true;       # KDE Connect integration
};
```

### Hardware Configuration

Match your hardware:

```nix
mySystem.hardware = {
  amd = true;              # Set false for Intel-only systems
  bluetooth = true;        # Set false if no Bluetooth
  steam = true;            # Set false if not gaming
};
```

**After changes, rebuild:**
```bash
# Test first (safe)
nh os test .#nixosConfigurations.Rig

# If test succeeds, apply changes
nh os switch .#nixosConfigurations.Rig
```

## Theme Customization

### Changing the Color Scheme

The system currently uses the Axion custom base16 theme. Edit `modules/system/desktop/stylix.nix`:

**Current configuration:**
```nix
stylix.base16Scheme = ./axion.yaml;  # Custom Axion theme file
```

**To create a custom theme:**
1. Create a YAML file in `modules/system/desktop/` (e.g., `my-theme.yaml`)
2. Define base16 colors following the base16 specification
3. Update stylix.nix to point to your theme file

**Example custom theme structure:**
```yaml
scheme: "My Theme Name"
author: "Your Name"
base00: "1b002b"  # Default background
base01: "1c0c25"  # Lighter background
base02: "261033"  # Selection background
# ... and so on for base03-base0F
```

**Base16 color meanings:**
- `base00-03`: Background shades (darkest to lighter)
- `base04-07`: Foreground shades (darker to lightest)
- `base08-0F`: Accent colors (red, orange, yellow, green, cyan, blue, magenta, brown)

**Using existing base16 themes:**
```nix
# Import from base16-schemes package
stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
```

### Changing the Wallpaper

The system uses `swww` for wallpaper management with automatic rotation every 15 minutes from `~/.local/share/wallpapers/`.

**To change wallpapers:**
1. Add your images to `~/.local/share/wallpapers/`
2. They will automatically rotate every 15 minutes via systemd timer
3. The wallpaper service is configured in `modules/home-manager/desktop/hyprland/wallpaper.nix`

**To change rotation interval:**
Edit the timer in `modules/home-manager/desktop/hyprland/wallpaper.nix`:
```nix
systemd.user.timers.rotate-wallpaper = {
  Timer = {
    OnBootSec = "2m";      # First rotation 2 minutes after boot
    OnUnitActiveSec = "15m";  # Rotate every 15 minutes (change this)
  };
};
```

**Note**: Stylix uses the `axion.yaml` color scheme directly, not wallpaper-based color extraction.

### Font Configuration

Edit font settings in `modules/system/desktop/stylix.nix`:

**Current configuration:**
```nix
stylix.fonts = {
  monospace = {
    package = pkgs.nerd-fonts.terminess-ttf;
    name = "Terminess Nerd Font";
  };
  sansSerif = {
    package = pkgs.google-fonts.override { fonts = ["Orbitron"]; };
    name = "Orbitron";
  };
  serif = {
    package = pkgs.google-fonts.override { fonts = ["SpaceGrotesk"]; };
    name = "Space Grotesk";
  };
  sizes = {
    applications = 12;
    terminal = 13;
    desktop = 10;
    popups = 12;
  };
};
```

**Note**: Font packages use the new `pkgs.nerd-fonts.*` and `pkgs.google-fonts` syntax.

## Desktop Environment

### Hyprland Configuration

Hyprland configuration is split across system and user levels:
- **System-level**: `modules/system/desktop/hyprland.nix` (enables Hyprland, XDG portals, PAM)
- **User-level**: `modules/home-manager/desktop/hyprland/` (focused modules for settings, keybinds, rules)

**Configuration structure:**
- `config.nix`: Hyprland settings (monitor, env, animations, workspace definitions)
- `keybinds.nix`: All keybindings and submap resize mode
- `rules.nix`: Window rules (workspace routing, opacity, float)
- `wallpaper.nix`: swww service and wallpaper systemd services
- `hyprlock.nix`: Screen lock configuration

**Workspace Customization:**

To modify workspace names or properties, edit `modules/home-manager/desktop/hyprland/config.nix`:

```nix
workspace = [
  "1, name:comms, gapsin:1, gapsout:2"
  "2, name:dev, gapsin:1, gapsout:2"
  "3, name:games, gapsin:0, gapsout:0, rounding:false"
  "4, name:media, gapsin:1, gapsout:2"
  "5, name:web, gapsin:1, gapsout:2"
  "special:control-panel, gapsin:10, gapsout:20"
];
```

**Modifying Keybindings:**

Edit `modules/home-manager/desktop/hyprland/keybinds.nix` to change keybindings:

```nix
bind = [
  "$mainMod, 1, workspace, name:comms"
  "$mainMod, 2, workspace, name:dev"
  # ... customize workspace navigation
  "$mainMod, grave, togglespecialworkspace, control-panel"
];
```

**Adding Window Routing Rules:**

Edit `modules/home-manager/desktop/hyprland/rules.nix` to route applications:

```nix
windowrulev2 = [
  # Route to specific workspace
  "workspace name:dev, class:^(Zed)$"
  "workspace name:web, class:^(brave-browser)$"
  "workspace name:media, class:^(io\.github\.htkhiem\.Euphonica)$"

  # Float specific window types
  "float, class:^(pavucontrol)$"

  # Opacity overrides (full opacity for specific apps)
  "opacity 1.0 override 1.0 override 1.0 override, class:^(vesktop)$"
];
```

**Finding Window Classes:**

```bash
# Run this, then click the window
hyprctl clients | grep class
```

**Auto-Launch Applications:**

Configure apps to start on specific workspaces at login:

```nix
exec-once = [
  "[workspace name:games] steam"
  "[workspace name:comms] vesktop"
  "hyprctl dispatch workspace name:comms"  # Start on this workspace
];
```

**Customizing Control-Panel Utilities:**

To add an application to the control-panel workspace, create a desktop entry override in `modules/home-manager/desktop/xdg-apps.nix`:

```nix
xdg.dataFile."applications/myapp.desktop".text = ''
  [Desktop Entry]
  Name=My App
  Exec=hyprctl dispatch exec '[workspace special:control-panel; tile] myapp'
  Type=Application
  Terminal=false
'';
```

**Monitor Configuration:**

For multi-monitor setups, edit the monitor section in `modules/home-manager/desktop/hyprland/config.nix`:

```nix
monitor = [
  "HDMI-A-2, 2560x1440@144, 0x0, 1"  # Primary monitor
  "DP-1, 1920x1080@60, 2560x0, 1"    # Secondary monitor
  ", preferred, auto, 1"               # Auto-configure other monitors
];
```

**Visual Customization:**

Adjust window appearance in `modules/home-manager/desktop/hyprland/config.nix`:

```nix
decoration = {
  rounding = 2;
  active_opacity = 0.90;
  inactive_opacity = 0.80;
  blur = {
    enabled = true;
    size = 3;
    passes = 1;
  };
};

general = {
  border_size = 3;
  gaps_in = 3;
  gaps_out = 6;
  layout = "dwindle";
};
```

### Waybar Configuration

Waybar is configured in `modules/home-manager/desktop/waybar/` with focused modules:
- `config.nix`: Bar layout and module definitions
- `style.nix`: Custom CSS styling

**Workspace Display:**

Edit workspace module configuration in `modules/home-manager/desktop/waybar/config.nix`:

```nix
"hyprland/workspaces" = {
  disable-scroll = false;
  all-outputs = true;
  format = "{name}";
  on-click = "activate";
  sort-by-number = true;
  persistent-workspaces = {
    "comms" = [ ];
    "web" = [ ];
    "dev" = [ ];
    "media" = [ ];
    "games" = [ ];
  };
};
```

**Customizing Module Order:**

To change what appears in waybar, edit the modules-left, modules-center, and modules-right arrays in `config.nix`:

```nix
modules-left = [ "tray" "hyprland/workspaces" ];
modules-center = [ "hyprland/window" ];
modules-right = [
  "network"
  "custom/temperature"
  "bluetooth"
  "pulseaudio"
  "clock"
  "bluetooth"
  "network"
  "pulseaudio"
  "cpu"
  "memory"
  "disk"
  "battery"
];
```

**Adding Custom Click Actions:**

Waybar modules support click actions for quick access:

```nix
network = {
  format-wifi = "{essid} ({signalStrength}%) ";
  format-ethernet = "{ipaddr}/{cidr} ";
  format-disconnected = "Disconnected ⚠";
  on-click-right = "hyprctl dispatch exec '[workspace special:control-panel; tile] ghostty nmtui'";
};

bluetooth = {
  format = " {status}";
  format-connected = " {device_alias}";
  on-click-right = "hyprctl dispatch exec '[workspace special:control-panel; tile] ghostty bluetui'";
};
```

## Adding Software

### System-Wide Packages

Add packages available to all users in `configuration.nix`:

```nix
environment.systemPackages = with pkgs; [
  # System utilities
  htop
  neofetch
  tree

  # Development tools
  docker
  postgresql

  # Applications
  brave
  vesktop

  # Your packages here
];
```

### User Packages

Add user-specific packages in `home.nix`:

```nix
home.packages = with pkgs; [
  # CLI tools
  ripgrep
  fd
  bat

  # Development
  nodejs
  python3

  # Applications
  spotify
  slack

  # Your packages here
];
```

### Finding Packages

```bash
# Search for packages
nix search nixpkgs package-name

# Search on the web
# Visit: https://search.nixos.org/packages
```

### Installing from Unstable

```nix
# In configuration.nix or home.nix
environment.systemPackages = with pkgs; [
  # Latest version from unstable
  unstable.package-name
];
```

## Creating Custom Configurations

### Method 1: Modify Existing Configuration

Edit `flake.nix` to add a new configuration:

```nix
nixosConfigurations.MyCustom = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {inherit inputs;};
  modules = [
    inputs.stylix.nixosModules.stylix
    ./configuration.nix
    {
      # Override specific features
      mySystem.features = {
        desktop = true;
        security = true;
        yubikey = false;
        claudeCode = true;
        development = true;
        gaming = false;      # Disable gaming
        flatpak = true;
        media = true;
        kdeconnect = false;
      };

      # Override hardware settings
      mySystem.hardware = {
        amd = true;
        bluetooth = true;
        steam = false;
      };
    }
  ];
};
```

**Build your custom configuration:**
```bash
nh os switch .#nixosConfigurations.MyCustom
```

### Method 2: Create Separate Configuration File

Create a new file like `my-config.nix`:

```nix
{ config, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/options.nix
    ./modules/core
    ./modules/security
    ./modules/desktop
    ./modules/development
    inputs.home-manager.nixosModules.default
  ];

  mySystem = {
    hostName = "my-system";
    user = {
      name = "myuser";
      description = "My User";
    };

    features = {
      # Your feature configuration
      desktop = true;
      security = true;
      yubikey = false;
      claudeCode = true;
      development = true;
      gaming = false;
      flatpak = true;
      media = true;
      kdeconnect = true;
    };

    hardware = {
      # Your hardware configuration
      amd = true;
      bluetooth = true;
      steam = false;
    };
  };

  # Home Manager
  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users.${config.mySystem.user.name} = import ./my-home.nix;
  };

  system.stateVersion = "24.11";
}
```

**Reference in `flake.nix`:**
```nix
MyConfig = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {inherit inputs;};
  modules = [
    inputs.stylix.nixosModules.stylix
    ./my-config.nix
  ];
};
```

## Service Configuration

### Adding System Services

In `configuration.nix`:

```nix
services.docker = {
  enable = true;
  enableOnBoot = true;
  autoPrune = {
    enable = true;
    dates = "weekly";
  };
};

virtualisation.libvirtd = {
  enable = true;
  qemu.ovmf.enable = true;
};
```

### Adding User Services

In `home.nix`:

```nix
systemd.user.services.my-service = {
  Unit = {
    Description = "My Custom Service";
    After = [ "graphical-session.target" ];
  };

  Service = {
    ExecStart = "${pkgs.my-package}/bin/my-command";
    Restart = "on-failure";
  };

  Install = {
    WantedBy = [ "graphical-session.target" ];
  };
};
```

### Modifying Existing Services

Override service options:

```nix
# Modify SSH service
services.openssh = {
  enable = true;
  settings = {
    PermitRootLogin = "no";
    PasswordAuthentication = false;
    Port = 2222;  # Custom port
  };
};
```

## Advanced Customization

### Creating Custom Modules

Create a new module in `modules/custom/my-feature.nix`:

```nix
{ config, lib, pkgs, ... }:
with lib;
{
  options.mySystem.features.myFeature = mkEnableOption "My custom feature";

  config = mkIf config.mySystem.features.myFeature {
    environment.systemPackages = with pkgs; [
      # Your packages
    ];

    services.myService = {
      enable = true;
      # Service configuration
    };
  };
}
```

**Import in `configuration.nix`:**
```nix
imports = [
  # ... existing imports
  ./modules/custom/my-feature.nix
];

mySystem.features.myFeature = true;
```

### Custom Shell Aliases

Add aliases in `modules/system/core/nix.nix` or `configuration.nix`:

```nix
environment.shellAliases = {
  # System management
  rebuild = "sudo nixos-rebuild switch --flake ~/dotfiles";
  update-system = "cd ~/dotfiles && nix flake update && sudo nixos-rebuild switch --flake .";

  # Common commands
  ll = "ls -lah";
  grep = "grep --color=auto";

  # Git shortcuts
  gs = "git status";
  ga = "git add";
  gc = "git commit";
  gp = "git push";

  # Your custom aliases
};
```

### Custom Scripts

Create scripts in `modules/system/core/nix.nix`:

```nix
environment.systemPackages = with pkgs; [
  (writeScriptBin "my-script" ''
    #!/usr/bin/env bash
    # Your script content
    echo "Hello from my custom script!"
  '')
];
```

### Adding Build Inputs

Add flake inputs in `flake.nix`:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  # ... existing inputs

  # Add new input
  my-input.url = "github:user/repo";
  my-input.inputs.nixpkgs.follows = "nixpkgs";
};
```

**Use in configuration:**
```nix
specialArgs = {
  inherit inputs;
  myInput = inputs.my-input;
};
```

### Environment Variables

System-wide environment variables:

```nix
environment.variables = {
  EDITOR = "vim";
  VISUAL = "zeditor";
  BROWSER = "brave";

  # Your variables
};
```

User-specific in `home.nix`:

```nix
home.sessionVariables = {
  MY_VAR = "value";
};
```

### Firewall Customization

Edit `modules/system/security/firewall.nix`:

```nix
# Open specific ports
networking.firewall.allowedTCPPorts = [
  2222    # SSH
  8080    # Custom service
];

networking.firewall.allowedUDPPorts = [
  51820   # WireGuard
];

# Port ranges
networking.firewall.allowedTCPPortRanges = [
  { from = 5000; to = 5010; }
];

# Allow specific interfaces
networking.firewall.trustedInterfaces = [ "virbr0" ];
```

### Boot Configuration

Customize boot options in `modules/system/core/boot.nix`:

```nix
boot = {
  # Kernel parameters
  kernelParams = [
    "quiet"
    "splash"
    "your-parameter"
  ];

  # Timeout
  loader.timeout = 5;

  # Different kernel
  kernelPackages = pkgs.linuxPackages_latest;
};
```

## Testing Your Changes

### Safe Testing Workflow

```bash
# 1. Make changes to configuration files
vim configuration.nix

# 2. Check syntax
nix flake check

# 3. Test without applying (uses nh)
nh os test .#nixosConfigurations.Rig

# 4. If successful, apply permanently (uses nh)
nh os switch .#nixosConfigurations.Rig

# 5. If something breaks, rollback
sudo nixos-rebuild switch --rollback
```

### Comparing Configurations

```bash
# See what will change
nix build .#nixosConfigurations.YourConfig.config.system.build.toplevel
nix store diff-closures /run/current-system ./result
```

### Debugging

```bash
# Verbose output
nh os switch .#nixosConfigurations.Rig -- --show-trace

# Check logs
journalctl -xe
journalctl -u service-name
```

## Backup and Version Control

### Git Workflow

```bash
cd ~/dotfiles

# Before making changes
git checkout -b my-customization

# After testing
git add .
git commit -m "Customize for my system"

# If successful
git checkout main
git merge my-customization

# If failed
git checkout main
```

### Configuration Backup

```bash
# Archive your configuration
nix flake archive --to ./backup

# Or use the alias
nfa
```

## Next Steps

- Review [Configuration Guide](CONFIGURATION.md) for more options
- Check [Features Guide](FEATURES.md) to understand what can be customized
- See [Troubleshooting Guide](TROUBLESHOOTING.md) if customizations fail

---

**Best Practice**: Always test configuration changes before applying them permanently, and keep your dotfiles in version control.
