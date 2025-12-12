# Installation Guide

This guide provides detailed step-by-step instructions for installing AnomalOS configuration on your NixOS system.

> **Important**: This configuration is designed for my personal hardware. While customization is supported, no guarantees are made that it will work on your system without modifications. Use at your own risk.

## Prerequisites

Before starting the installation, ensure you have:

- Fresh NixOS installation on an x86_64 machine
- Internet connection for downloading packages
- Root or sudo access to the system
- Basic familiarity with command line operations
- YubiKey device (required for Rig configuration)
- Sufficient storage: At least 50GB free (100GB+ recommended)

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
# Clone from GitHub
git clone https://github.com/weegs710/AnomalOS.git ~/dotfiles

# Or clone from Codeberg
git clone https://codeberg.org/weegs710/AnomalOS.git ~/dotfiles

# Navigate to the directory
cd ~/dotfiles

# Verify you're in the right directory
ls -la
# You should see: flake.nix, configuration.nix, home.nix, modules/, etc.
```

### Step 3: Understand ZFS Requirements

**IMPORTANT**: This configuration uses ZFS for the root filesystem.

**ZFS Prerequisites:**
- NixOS must be installed on ZFS (use ZFS option during installation)
- Requires hardware-configuration file customized for ZFS pools
- This repository includes `hardware-configuration-zfs.nix` as reference

**If you're NOT using ZFS:**
You'll need to modify `configuration.nix` to use a standard ext4/btrfs configuration and generate a standard hardware config:

```bash
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
# Then update configuration.nix to import ./hardware-configuration.nix instead
```

**If you ARE using ZFS:**
Review and customize `hardware-configuration-zfs.nix` for your pools and mount points. The reference configuration includes:
- `zroot` pool for system (/, /nix, /cache, /persist)
- Optional `zgames` pool for gaming storage
- ZFS ARC memory limits (4-16GB)

### Step 4: Customize Configuration (Optional but Recommended)

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

### Step 5: Test Configuration

**ALWAYS test before switching** to avoid breaking your system:

```bash
# Test the Rig configuration
# NOTE: Use nixos-rebuild for initial installation (nh not available yet)
sudo nixos-rebuild test --flake .#nixosConfigurations.Rig
```

**What to expect during test:**
- Download and build process (can take 10-30 minutes on first run)
- Large amount of console output
- No errors in final output
- System remains functional

**If test fails:**
- Read error messages carefully
- Verify ZFS pools are properly configured if using ZFS
- Check that you have internet connectivity
- Check the [Troubleshooting Guide](TROUBLESHOOTING.md)

### Step 6: Apply Configuration

**Only proceed if Step 5 completed successfully:**

```bash
# Apply the configuration
# NOTE: Use nixos-rebuild for initial installation (nh not available yet)
sudo nixos-rebuild switch --flake .#nixosConfigurations.Rig
```

**What happens during switch:**
- System configuration is applied
- Services are started/restarted
- Boot loader is updated
- User environment is configured
- `nh` (Nix Helper) is installed for future rebuilds

### Step 7: Reboot

```bash
# Reboot to ensure everything loads correctly
sudo reboot
```

### Step 8: Post-Installation Setup

After rebooting, perform configuration-specific setup:

#### YubiKey Configuration

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

#### Claude Code Setup

Test Claude Code is available:

```bash
# Check Claude Code is installed
claude --version

# Test the cc command (enhanced project launcher)
cc status

# Launch Claude Code
claude
```

#### System Commands Available

After installation, use `nh` (Nix Helper) for future rebuilds:

```bash
# Test configuration changes
nrt-rig     # Alias for: nh os test .#nixosConfigurations.Rig

# Apply configuration changes
nrs-rig     # Alias for: nh os switch .#nixosConfigurations.Rig

# Update and rebuild interactively
rig-up      # Updates flake, tests, and prompts to switch
```

## Verification Checklist

After installation, verify these items:

- [ ] System boots successfully
- [ ] Desktop environment loads (Hyprland + Waybar)
- [ ] Network connectivity works
- [ ] Audio is functional (`systemctl --user status pipewire`)
- [ ] Keyboard and mouse work correctly
- [ ] Display resolution is correct
- [ ] YubiKey authentication requires YubiKey touch
- [ ] `cc` command is available
- [ ] `nh` command is available (`nh --help`)

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
# Use nixos-rebuild if nh not installed yet
sudo nixos-rebuild test --flake .#nixosConfigurations.Rig
# Or use nh if already installed
nh os test .#nixosConfigurations.Rig
```

### Hardware Configuration Issues

**For ZFS systems:**
```bash
# Verify ZFS pools are imported
zpool status

# Check ZFS datasets are mounted
zfs list
df -h | grep zfs

# Ensure hardware-configuration-zfs.nix references correct pools
cat hardware-configuration-zfs.nix | grep -A 3 "fileSystems"
```

**For non-ZFS systems:**
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

## Recovery

If the system becomes unbootable:

1. **Boot from NixOS installer** USB
2. **Import ZFS pools and mount filesystems**:
   ```bash
   # Import ZFS pools
   sudo zpool import -f zroot
   sudo zpool import -f zgames  # if you have zgames pool

   # Mount ZFS root
   sudo mount -t zfs zroot/root /mnt

   # Mount boot partition
   sudo mount /dev/nvme1n1p1 /mnt/boot  # adjust device as needed

   # Mount other ZFS datasets
   sudo mount -t zfs zroot/nix /mnt/nix
   sudo mount -t zfs zroot/persist /mnt/persist
   sudo mount -t zfs zroot/cache /mnt/cache
   ```
3. **Rebuild from mounted system**:
   ```bash
   sudo nixos-rebuild switch --flake /mnt/home/your-username/dotfiles#nixosConfigurations.Rig
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
4. Open an issue on [GitHub](https://github.com/weegs710/AnomalOS/issues) or [Codeberg](https://codeberg.org/weegs710/AnomalOS/issues)

---

**Remember**: This configuration is provided as-is with no guarantees. Always test before applying, and keep backups of important data.
