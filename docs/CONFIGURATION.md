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
  aiAssistant = true;    # Ollama + Open WebUI
};
```

**Feature Descriptions:**

- **desktop**: Enables Hyprland compositor, Waybar, SDDM, Stylix theming
- **security**: Enables firewall, Suricata IDS, kernel hardening, SSH hardening
- **yubikey**: Enables YubiKey U2F for login, sudo, and polkit
- **claudeCode**: Installs Claude Code with enhanced project management
- **development**: Installs editors, language servers, development toolchains
- **gaming**: Installs Steam, Lutris, emulators, gaming optimizations
- **aiAssistant**: Installs Ollama, Open WebUI, and NixOS expert model

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

- **amd**: Enables AMD GPU drivers, ROCm for AI workloads, GPU acceleration
- **nvidia**: Enables proprietary NVIDIA drivers and CUDA support
- **bluetooth**: Enables Bluetooth stack with bluetui interface
- **steam**: Enables Steam with Proton, Gamescope, hardware compatibility

## The Four Configurations

AnomalOS provides four pre-defined configurations in `flake.nix`:

### 1. Rig (Full Featured)

```nix
# All features enabled
features = {
  desktop = true;
  security = true;
  yubikey = true;        # ✅ Enabled
  claudeCode = true;     # ✅ Enabled
  development = true;
  gaming = true;
  aiAssistant = true;
};
```

**Best for:** Primary development workstation with maximum security

### 2. Hack (Developer Focused)

```nix
# YubiKey disabled via mkForce
features = {
  desktop = true;
  security = true;
  yubikey = false;       # ❌ Disabled
  claudeCode = true;     # ✅ Enabled
  development = true;
  gaming = true;
  aiAssistant = true;
};
```

**Best for:** Development without hardware authentication requirements

### 3. Guard (Security Focused)

```nix
# Claude Code disabled via mkForce
features = {
  desktop = true;
  security = true;
  yubikey = true;        # ✅ Enabled
  claudeCode = false;    # ❌ Disabled
  development = true;
  gaming = true;
  aiAssistant = true;
};
```

**Best for:** Security-conscious users who prefer other development tools

### 4. Stub (Minimal)

```nix
# YubiKey and Claude Code disabled
features = {
  desktop = true;
  security = true;
  yubikey = false;       # ❌ Disabled
  claudeCode = false;    # ❌ Disabled
  development = true;
  gaming = true;
  aiAssistant = true;
};
```

**Best for:** Basic desktop system without specialized security or AI tools

## Module Configuration

### Core Modules

Located in `modules/core/`:

- **boot.nix**: Boot loader configuration, kernel parameters, CachyOS kernel
- **networking.nix**: NetworkManager, firewall basics, hostname
- **nix.nix**: Nix settings, garbage collection, shell aliases, update scripts
- **users.nix**: User account creation and group membership

### Security Modules

Located in `modules/security/`:

- **firewall.nix**: nftables configuration, custom gaming ports (23243-23262), SSH on port 2222
- **hardening.nix**: Kernel sysctl parameters, SSH hardening, PAM configuration
- **suricata.nix**: Intrusion detection system, network monitoring
- **yubikey.nix**: YubiKey U2F authentication, auto-login, polkit integration

**Security Configuration Options:**

Edit `modules/security/firewall.nix` to adjust ports:
```nix
# Open additional TCP ports
networking.firewall.allowedTCPPorts = [ 2222 ];

# Open custom port ranges
networking.firewall.allowedTCPPortRanges = [
  { from = 23243; to = 23262; }  # Divinity Original Sin 2
];
```

### Desktop Modules

Located in `modules/desktop/`:

- **hyprland.nix**: Hyprland compositor, utilities (grim, slurp, wl-clipboard)
- **media.nix**: Applications (GIMP, LibreWolf, Anki, Vesktop), media tools
- **stylix.nix**: Theme configuration (Purple Colony color scheme)

**Theme Customization:**

Edit `modules/desktop/stylix.nix` to change colors:
```nix
stylix.base16Scheme = {
  base00 = "1b002b";  # Background
  base05 = "b392f0";  # Foreground
  # ... more color definitions
  scheme = "Purple Colony";
};
```

Change wallpaper:
```nix
stylix.image = ./your-wallpaper.jpg;
```

### Development Modules

Located in `modules/development/`:

- **editors.nix**: VSCodium with GitHub Copilot, tmux, starship
- **languages.nix**: Node.js, Python3, Rust, language servers (nil, hyprls)
- **claude-code.nix**: Claude Code installation and integration
- **ai-assistant.nix**: Ollama + Open WebUI configuration

**Claude Code Configuration:**

Managed by `modules/claude-code-enhanced/default.nix`:
- Pre-approved commands for autonomous operation
- MCP server integration (Serena)
- Global project management via `cc` command
- Custom slash commands (/primer, /analyze, /generate, /execute)

**AI Assistant Configuration:**

Edit `modules/development/ai-assistant.nix` for Ollama settings:
```nix
Environment = [
  "OLLAMA_HOST=127.0.0.1:11434"
  "OLLAMA_NUM_CTX=32000"        # Context window size
];
```

### Gaming Modules

Located in `modules/gaming/`:

- **steam.nix**: Steam with Proton, hardware compatibility
- **default.nix**: Lutris, PPSSPP, DeSmuME emulators

## Home Manager Configuration

User-level configuration in `home.nix`:

### Shell Configuration

```nix
programs.fish = {
  enable = true;
  # Fish shell customization
};

programs.starship = {
  enable = true;
  # Starship prompt customization
};
```

### Terminal Configuration

```nix
programs.kitty = {
  enable = true;
  settings = {
    font_size = 12;
    # Kitty terminal settings
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

## Backup Configuration

Restic backup service in `configuration.nix`:

```nix
services.restic.backups.localbackup = {
  initialize = true;
  repository = "/backup/restic-repo";          # Backup location
  passwordFile = "/etc/nixos/restic-password"; # Password file

  paths = [
    "/home/${config.mySystem.user.name}"
    "/etc/nixos"
  ];

  exclude = [
    "/home/${config.mySystem.user.name}/.cache"
    "/home/${config.mySystem.user.name}/.local/share/Steam"
    "/home/${config.mySystem.user.name}/Downloads"
  ];

  timerConfig = {
    OnCalendar = "daily";  # Backup frequency
    Persistent = true;
  };

  pruneOpts = [
    "--keep-daily 7"      # Keep 7 daily backups
    "--keep-weekly 5"     # Keep 5 weekly backups
    "--keep-monthly 12"   # Keep 12 monthly backups
  ];
};
```

## Shell Aliases and Functions

Defined in `modules/core/nix.nix`:

### Quick Rebuild Aliases

```bash
nrs-rig       # Switch to Rig configuration
nrt-rig       # Test Rig configuration
nrs-hack      # Switch to Hack configuration
nrt-hack      # Test Hack configuration
nrs-guard     # Switch to Guard configuration
nrt-guard     # Test Guard configuration
nrs-stub      # Switch to Stub configuration
nrt-stub      # Test Stub configuration
```

### Update Functions

```bash
rig-up        # Update + test + prompt to switch (Rig)
hack-up       # Update + test + prompt to switch (Hack)
guard-up      # Update + test + prompt to switch (Guard)
stub-up       # Update + test + prompt to switch (Stub)
```

### Utility Aliases

```bash
update        # Update flake inputs
nfa           # Archive flake for sharing
recycle       # Clean old system generations (7 days)
```

### AI Assistant Aliases

```bash
ai            # Launch CLI assistant (klank-cli)
ai-cli        # Launch CLI assistant
ai-web        # Launch Web UI in browser (klank)
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
    inputs.cachyos.nixosModules.default
    ./configuration.nix
    {
      mySystem.features = {
        desktop = true;
        security = true;
        yubikey = false;      # Your custom settings
        claudeCode = true;
        development = true;
        gaming = false;       # Disable gaming
        aiAssistant = true;
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

User packages in `home.nix`:
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
# Always test before switching
sudo nixos-rebuild test --flake .#Rig

# If successful, then switch
sudo nixos-rebuild switch --flake .#Rig
```

## Next Steps

- Review [Features Guide](FEATURES.md) for detailed feature documentation
- Check [Customization Guide](CUSTOMIZATION.md) for advanced modifications
- See [Troubleshooting Guide](TROUBLESHOOTING.md) if you encounter issues

---

**Remember**: Configuration changes should always be tested before applying permanently. Keep backups of your working configuration.
