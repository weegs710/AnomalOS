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

Edit `modules/desktop/stylix.nix`:

```nix
stylix.base16Scheme = {
  base00 = "1b002b";  # Default background
  base01 = "1c0c25";  # Lighter background
  base02 = "261033";  # Selection background
  base03 = "2f143f";  # Comments, invisible
  base04 = "16081f";  # Dark foreground
  base05 = "b392f0";  # Default foreground
  base06 = "c7aaff";  # Light foreground
  base07 = "ffffff";  # Lightest foreground
  base08 = "ff6666";  # Red (errors, deletions)
  base09 = "ffaa55";  # Orange (warnings, numbers)
  base0A = "ffff66";  # Yellow (classes, search)
  base0B = "aaffaa";  # Green (strings, additions)
  base0C = "66ccff";  # Cyan (support, regex)
  base0D = "9999ff";  # Blue (functions, headings)
  base0E = "cc66cc";  # Magenta (keywords, tags)
  base0F = "a565f0";  # Brown (deprecated)

  scheme = "Your Theme Name";
  author = "Your Name";
};
```

**Base16 color meanings:**
- `base00-03`: Background shades (dark to light)
- `base04-07`: Foreground shades (dark to light)
- `base08-0F`: Accent colors (semantic meanings)

**Using existing base16 themes:**
```nix
# Import from base16 repository
stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
```

### Changing the Wallpaper

The system uses `swww` for wallpaper management with automatic rotation every 3 minutes from `~/.local/share/wallpapers/`.

To change wallpapers:
1. Add your images to `~/.local/share/wallpapers/`
2. They will automatically rotate every 3 minutes

**Note**: Stylix uses the `anomal-16.yaml` color scheme directly, not wallpaper-based color extraction.

### Font Configuration

Edit font settings in `modules/desktop/stylix.nix` or `home.nix`:

```nix
stylix.fonts = {
  monospace = {
    package = pkgs.nerdfonts;
    name = "JetBrainsMono Nerd Font";
  };
  sansSerif = {
    package = pkgs.dejavu_fonts;
    name = "DejaVu Sans";
  };
  serif = {
    package = pkgs.dejavu_fonts;
    name = "DejaVu Serif";
  };
  sizes = {
    applications = 12;
    terminal = 14;
    desktop = 10;
    popups = 12;
  };
};
```

## Desktop Environment

### Hyprland Configuration

System-level Hyprland is configured in `modules/desktop/hyprland.nix`. The current setup uses named workspaces with automatic window routing.

**Workspace Customization:**

To modify workspace names or keybinds, edit `modules/desktop/hyprland.nix`:

```nix
# Define workspace properties
workspace = [
  "1, name:comms, gapsin:1, gapsout:2"
  "2, name:dev, gapsin:1, gapsout:2"
  "3, name:games, gapsin:0, gapsout:0, rounding:false"
  "4, name:media, gapsin:1, gapsout:2"
  "5, name:web, gapsin:1, gapsout:2"
  "special:control-panel, gapsin:10, gapsout:20"
];

# Workspace navigation keybinds
bind = [
  "$mainMod, 1, workspace, name:comms"
  "$mainMod, 2, workspace, name:dev"
  # ... more workspace binds
  "$mainMod, grave, togglespecialworkspace, control-panel"
];
```

**Adding Window Routing Rules:**

Route specific applications to workspaces by window class:

```nix
windowrulev2 = [
  # Route to specific workspace
  "workspace name:dev, class:^(code)$"
  "workspace name:web, class:^(firefox)$"

  # Float specific window types
  "float, class:^(pavucontrol)$"

  # Opacity overrides
  "opacity 1.0 override, class:^(vlc)$"
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
  "[workspace name:media silent] vlc"
  "hyprctl dispatch workspace name:comms"  # Start on this workspace
];
```

**Customizing Control-Panel Utilities:**

To add an application to the control-panel workspace, create a desktop entry override in `modules/desktop/default.nix`:

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

For multi-monitor setups, edit the monitor section in `modules/desktop/hyprland.nix`:

```nix
monitor = [
  "DP-1,2560x1440@144,0x0,1"
  "HDMI-A-1,1920x1080@60,2560x0,1"
  ",preferred,auto,1"  # Auto-configure other monitors
];
```

**Visual Customization:**

Adjust window appearance in the decoration and general sections:

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
  border_size = 1;
  gaps_in = 1;
  gaps_out = 2;
  layout = "dwindle";
};
```

### Waybar Configuration

Waybar is configured in `modules/desktop/hyprland.nix` and integrates with the named workspace system.

**Workspace Display:**

The workspace module shows named workspaces in the correct order:

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

To change what appears in waybar, edit the modules-left, modules-center, and modules-right arrays:

```nix
modules-left = [ "hyprland/workspaces" "hyprland/window" ];
modules-center = [ "clock" ];
modules-right = [
  "tray"
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
  firefox
  thunderbird

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

Add aliases in `modules/core/nix.nix` or `configuration.nix`:

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

Create scripts in `modules/core/nix.nix`:

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
  VISUAL = "code";
  BROWSER = "firefox";

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

Edit `modules/security/firewall.nix`:

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

Customize boot options in `modules/core/boot.nix`:

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
