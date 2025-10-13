# Installation Guide

This guide provides detailed step-by-step instructions for installing AnomalOS configuration on your NixOS system.

> **⚠️ Important**: This configuration is designed for my personal hardware. While customization is supported, **no guarantees are made that it will work on your system without modifications**. Use at your own risk.

## Prerequisites

Before starting the installation, ensure you have:

- **Fresh NixOS installation** on an x86_64 machine
- **Internet connection** for downloading packages
- **Root or sudo access** to the system
- **Basic familiarity** with command line operations
- **YubiKey device** (optional, only for Rig/Guard configurations)
- **Sufficient storage**: At least 50GB free (100GB+ recommended)

## Step-by-Step Installation

### Step 1: Prepare Your System

First, ensure you're in a clean directory and have git available:

```bash
# Change to home directory
cd ~

# Install git if not already available
nix-shell -p git

# Verify git is working
git --version
```

### Step 2: Clone the Repository

Clone this configuration to `~/dotfiles`:

```bash
# Clone the repository
git clone https://github.com/weegs710/AnomalOS.git ~/dotfiles

# Navigate to the directory
cd ~/dotfiles

# Verify you're in the right directory
ls -la
# You should see: flake.nix, configuration.nix, home.nix, modules/, etc.
```

### Step 3: Generate Hardware Configuration

**IMPORTANT**: This step generates hardware-specific configuration for your system:

```bash
# Generate hardware configuration (overwrites existing file)
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix

# Verify the file was created
ls -lh hardware-configuration.nix
# File should exist and be larger than 0 bytes
```

### Step 4: Choose Your Configuration

Select one of the four available configurations based on your needs:

| Configuration | Use Case | Features |
|---------------|----------|----------|
| **Rig** | Full-featured development machine | YubiKey + Claude Code + Gaming + Desktop + AI |
| **Hack** | Development without hardware security | Claude Code + Gaming + Desktop + AI (no YubiKey) |
| **Guard** | Security-focused workstation | YubiKey + Gaming + Desktop + AI (no Claude Code) |
| **Stub** | Minimal desktop system | Gaming + Desktop + AI only |

### Step 5: Customize Configuration (Optional but Recommended)

Before building, customize `configuration.nix` with your preferences:

```bash
# Edit configuration.nix with your preferred editor
nano configuration.nix
# or
vim configuration.nix
```

**Minimum recommended changes:**

```nix
mySystem = {
  hostName = "your-hostname";        # Change to your preferred hostname
  user = {
    name = "your-username";          # Change to your username
    description = "Your Name";       # Change to your name
  };

  # Adjust hardware features for your system
  hardware = {
    amd = true;                      # Set false if you don't have AMD GPU
    nvidia = false;                  # Set true if you have NVIDIA GPU
    bluetooth = true;                # Set false if you don't need Bluetooth
    steam = true;                    # Set false if you don't game
  };
};
```

### Step 6: Test Configuration

**ALWAYS test before switching** to avoid breaking your system:

```bash
# Test your chosen configuration (replace 'Rig' with your choice)
sudo nixos-rebuild test --flake .#Rig
```

**What to expect during test:**
- Download and build process (can take 10-30 minutes on first run)
- Large amount of console output
- No errors in final output
- System remains functional

**If test fails:**
- Read error messages carefully
- Verify `hardware-configuration.nix` was generated correctly
- Check that you have internet connectivity
- Try a simpler configuration (e.g., Stub) first
- Check the [Troubleshooting Guide](TROUBLESHOOTING.md)

### Step 7: Apply Configuration

**Only proceed if Step 6 completed successfully:**

```bash
# Apply the configuration (replace 'Rig' with your choice)
sudo nixos-rebuild switch --flake .#Rig
```

**What happens during switch:**
- System configuration is applied
- Services are started/restarted
- Boot loader is updated
- User environment is configured

### Step 8: Reboot

```bash
# Reboot to ensure everything loads correctly
sudo reboot
```

### Step 9: Post-Installation Setup

After rebooting, perform configuration-specific setup:

#### For YubiKey Configurations (Rig/Guard)

Register your YubiKey for authentication:

```bash
# Create YubiKey configuration directory
mkdir -p ~/.config/Yubico

# Register your YubiKey
pamu2fcfg > ~/.config/Yubico/u2f_keys

# Test YubiKey authentication
sudo echo "YubiKey working!"  # Should require YubiKey touch
```

**YubiKey Auto-login:**
- System automatically logs you in when registered YubiKey is present
- Auto-login is disabled when YubiKey is unplugged
- Check logs: `sudo journalctl -u yubikey-autologin-init`

#### For Claude Code Configurations (Rig/Hack)

Test Claude Code is available:

```bash
# Check Claude Code is installed
claude --version

# Test the cc command (enhanced project launcher)
cc status

# Launch Claude Code
claude
```

#### For AI Assistant Configurations (All)

Test Ollama and Open WebUI:

```bash
# Check services are running
systemctl --user status ollama
systemctl --user status open-webui

# Launch CLI assistant
klank-cli
# or
ai

# Launch Web UI in browser
klank
# or
ai-web
```

Deploy AI models (first time only):

```bash
# Deploy the nix-expert model
deploy-ai-models
```

## Verification Checklist

After installation, verify these items:

- [ ] System boots successfully
- [ ] Desktop environment loads (Hyprland + Waybar)
- [ ] Network connectivity works
- [ ] Audio is functional (`systemctl --user status pipewire`)
- [ ] Keyboard and mouse work correctly
- [ ] Display resolution is correct
- [ ] If using YubiKey: Authentication requires YubiKey touch
- [ ] If using Claude Code: `cc` command is available
- [ ] If using AI Assistant: `klank` and `ai` commands work

## What Happens During Installation

Understanding the installation process:

1. **Downloads**: NixOS downloads all required packages (several GB)
2. **Builds**: System compiles necessary components
3. **Configuration**: Applies all module settings
4. **Services**: Starts configured services
5. **User Environment**: Sets up Home Manager configuration
6. **Boot Loader**: Updates GRUB/systemd-boot configuration

## Common Installation Issues

### Build Failures

```bash
# Clean and retry
sudo nix-collect-garbage -d
nix flake update
sudo nixos-rebuild test --flake .#Rig
```

### Hardware Configuration Issues

```bash
# Regenerate hardware configuration
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix

# Verify file contents
cat hardware-configuration.nix
```

### Network Issues During Build

```bash
# Test network connectivity
ping nixos.org

# Check DNS resolution
nslookup cache.nixos.org

# Verify network is up
ip addr show
```

### Out of Disk Space

```bash
# Check available space
df -h

# Clean up if needed
sudo nix-collect-garbage -d
```

## Switching Between Configurations

You can switch between the four configurations at any time:

```bash
# Test a different configuration first
sudo nixos-rebuild test --flake .#Hack

# If test succeeds, switch to it
sudo nixos-rebuild switch --flake .#Hack
```

Or use the convenient aliases:

```bash
# Using interactive update scripts
hack-up     # Updates, tests, and prompts to switch to Hack
guard-up    # Updates, tests, and prompts to switch to Guard
stub-up     # Updates, tests, and prompts to switch to Stub
rig-up      # Updates, tests, and prompts to switch to Rig
```

## Recovery

If the system becomes unbootable:

1. **Boot from NixOS installer** USB
2. **Mount your filesystems**:
   ```bash
   sudo mount /dev/sdXY /mnt
   sudo mount /dev/sdXZ /mnt/boot  # if separate boot partition
   ```
3. **Rebuild from mounted system**:
   ```bash
   sudo nixos-rebuild switch --flake /mnt/home/your-username/dotfiles#Stub
   ```
4. **Reboot**

## Next Steps

After successful installation:

1. Read the [Configuration Guide](CONFIGURATION.md) to understand options
2. Review the [Features Guide](FEATURES.md) to learn what's available
3. Check the [Customization Guide](CUSTOMIZATION.md) to personalize your system
4. Bookmark the [Troubleshooting Guide](TROUBLESHOOTING.md) for future reference

## Getting Help

If you encounter issues:

1. Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
2. Review [NixOS Manual](https://nixos.org/manual/nixos/stable/)
3. Search [NixOS Discourse](https://discourse.nixos.org/)
4. Open an issue on [GitHub](https://github.com/weegs710/AnomalOS/issues)

---

**Remember**: This configuration is provided as-is with no guarantees. Always test before applying, and keep backups of important data.
