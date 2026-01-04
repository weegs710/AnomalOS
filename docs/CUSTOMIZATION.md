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
- [Further Customization](#further-customization)

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

The system currently uses the Noctalia shell UI with dynamic theming via matugen. The theme is configured in `modules/home-manager/desktop/noctalia/settings.nix`.

**Current configuration:**
```nix
"theme" = {
  "matugen" = {
    "scheme" = "scheme-fruit-salad";  # Current color scheme
  };
};
```

**Available matugen schemes:**
- `scheme-content`: Content-based color extraction
- `scheme-fruit-salad`: Vibrant, fruity color palette (current)
- `scheme-monochrome`: Monochrome grayscale theme
- `scheme-neutral`: Neutral, subdued colors
- `scheme-tonal-spot`: Material You tonal spot colors
- `scheme-vibrant`: High-saturation vibrant colors
- `scheme-expressive`: Bold, expressive color combinations
- `scheme-fidelity`: High color fidelity
- `scheme-rainbow`: Full spectrum rainbow colors

**To change the color scheme:**
1. Edit `modules/home-manager/desktop/noctalia/settings.nix`
2. Change the `"scheme"` value to one of the schemes above
3. Rebuild with `nh os switch .#nixosConfigurations.Rig`
4. Noctalia will regenerate colors on next launch

**GTK Theme:**
The system uses `adw-gtk3` dark theme for GTK applications. This integrates with noctalia's color scheme for consistent theming.

**Legacy Theming:**
Stylix is disabled system-wide but remains available in the repository. Axion custom base16 color scheme files are preserved in `modules/home-manager/desktop/axion.yaml` for potential re-enablement.

### Changing the Wallpaper

The system uses noctalia for wallpaper management with automatic rotation every 10 minutes from `~/.local/share/wallpapers/`.

**To change wallpapers:**
1. Add your images to `~/.local/share/wallpapers/`
2. They will automatically rotate every 10 minutes via noctalia
3. Transitions use wave animation with 5-second duration

**To change rotation interval and transitions:**
Edit the wallpaper section in `modules/home-manager/desktop/noctalia/settings.nix`:
```nix
"wallpaper" = {
  "random" = {
    "enabled" = true;
    "interval" = 600;  # Rotation interval in seconds (600 = 10 minutes)
  };
  "transitions" = {
    "enabled" = true;
    "duration" = 5000;        # Transition duration in milliseconds
    "type" = "wave";          # Transition type: wave, grow, fade, etc.
    "edge_smoothness" = 0.5;  # Edge smoothing (0.0-1.0)
  };
};
```

**Supported transition types:**
- `wave`: Wave animation (current)
- `grow`: Growing circle transition
- `fade`: Crossfade transition
- `none`: Instant change

### Font Configuration

Noctalia uses SpaceMono Nerd Font for the shell UI. Font configuration is managed in `modules/home-manager/desktop/noctalia/gui-settings.json`:

**Current configuration:**
```nix
"ui" = {
  "fontDefault" = "SpaceMono Nerd Font";         # Default UI font
  "fontDefaultScale" = 1;                        # Default font scale
  "fontFixed" = "SpaceMono Nerd Font Mono";      # Fixed-width (monospace) font
  "fontFixedScale" = 1;                          # Fixed font scale
};
```

**To change fonts:**
1. Edit `modules/home-manager/desktop/noctalia/gui-settings.json`
2. Update the `ui.fontDefault` and `ui.fontFixed` values
3. Rebuild with `nh os switch .#nixosConfigurations.Rig`

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

### Noctalia Shell Bar Configuration

Noctalia shell bar is configured in `modules/home-manager/desktop/noctalia/settings.nix`.

**Bar Settings:**

```nix
"bar" = {
  "outer_corners" = false;  # Disable rounded outer corners
  "outline" = true;         # Enable outline
  "max_width" = 300;       # Maximum bar width
  "active_window" = {
    "max_width" = 300;     # Active window title max width
  };
  "media_mini" = "wave";   # Media visualizer type
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
    # inputs.stylix.nixosModules.stylix  # Disabled, using noctalia
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
    # inputs.stylix.nixosModules.stylix  # Disabled, using noctalia
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

## Further Customization

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
