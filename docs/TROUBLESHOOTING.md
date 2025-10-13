# Troubleshooting Guide

This guide helps resolve common issues you may encounter with AnomalOS configuration.

> **Important**: This configuration is designed for my specific hardware. Some issues may be related to hardware differences. Solutions provided are general guidance without guarantees.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Boot Problems](#boot-problems)
- [Desktop Environment Issues](#desktop-environment-issues)
- [Hardware Issues](#hardware-issues)
- [Service Issues](#service-issues)
- [YubiKey Issues](#yubikey-issues)
- [AI Assistant Issues](#ai-assistant-issues)
- [Network Issues](#network-issues)
- [General Debugging](#general-debugging)

## Installation Issues

### Build Failures

**Symptom**: `nixos-rebuild` fails with build errors

**Solutions:**

1. **Clean and retry:**
   ```bash
   sudo nix-collect-garbage -d
   nix flake update
   sudo nixos-rebuild test --flake .#YourConfig
   ```

2. **Check available disk space:**
   ```bash
   df -h
   # Need at least 10GB free
   ```

3. **Check internet connectivity:**
   ```bash
   ping nixos.org
   curl -I https://cache.nixos.org
   ```

4. **Clear Nix store lock:**
   ```bash
   sudo rm /nix/var/nix/db/big-lock
   ```

5. **Rebuild Nix database:**
   ```bash
   sudo nix-store --verify --check-contents --repair
   ```

### Hash Mismatch Errors

**Symptom**: `hash mismatch` errors during build

**Solutions:**

1. **Update flake lock:**
   ```bash
   nix flake update
   ```

2. **Clear specific input:**
   ```bash
   nix flake lock --update-input nixpkgs
   ```

3. **Clear evaluation cache:**
   ```bash
   rm -rf ~/.cache/nix
   ```

### Hardware Configuration Issues

**Symptom**: System fails to recognize hardware

**Solutions:**

1. **Regenerate hardware config:**
   ```bash
   sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
   ```

2. **Check for missing firmware:**
   ```bash
   dmesg | grep -i firmware
   ```

3. **Add firmware packages:**
   ```nix
   # In configuration.nix
   hardware.enableAllFirmware = true;
   ```

## Boot Problems

### System Won't Boot

**Solutions:**

1. **Boot from NixOS installer and chroot:**
   ```bash
   sudo mount /dev/sdXY /mnt
   sudo mount /dev/sdXZ /mnt/boot
   sudo nixos-enter --root /mnt
   ```

2. **Rollback to previous generation:**
   - At boot, select previous generation from boot menu
   - Or from running system:
   ```bash
   sudo nixos-rebuild switch --rollback
   ```

3. **Rebuild from installer:**
   ```bash
   sudo nixos-rebuild switch --flake /mnt/home/username/dotfiles#Stub
   ```

### Boot Hangs

**Symptom**: System hangs during boot

**Solutions:**

1. **Add verbose boot:**
   ```nix
   # In modules/core/boot.nix
   boot.kernelParams = [ "debug" "verbose" ];
   ```

2. **Check systemd services:**
   ```bash
   systemctl list-jobs
   systemctl --failed
   ```

3. **Disable problematic service temporarily:**
   ```nix
   systemd.services.problematic-service.enable = false;
   ```

### Kernel Panic

**Solutions:**

1. **Use different kernel:**
   ```nix
   # In configuration.nix, temporarily override
   boot.kernelPackages = pkgs.linuxPackages;
   ```

2. **Check kernel logs:**
   ```bash
   journalctl -k
   ```

## Desktop Environment Issues

### Hyprland Won't Start

**Symptom**: Black screen or Hyprland crashes

**Solutions:**

1. **Check Hyprland logs:**
   ```bash
   cat /tmp/hypr/$(ls -t /tmp/hypr/ | head -1)/hyprland.log
   ```

2. **Try starting Hyprland manually:**
   ```bash
   Hyprland
   ```

3. **Check if Wayland is available:**
   ```bash
   echo $XDG_SESSION_TYPE
   ls -la /run/user/1000/wayland-*
   ```

4. **Verify GPU drivers:**
   ```bash
   lspci -k | grep -A 3 -i vga
   ```

5. **Disable Hyprland temporarily and use fallback:**
   ```nix
   # In configuration.nix
   mySystem.features.desktop = false;
   # And enable basic X11
   services.xserver.enable = true;
   ```

### Display Issues

**Symptom**: Wrong resolution, black screen, or flickering

**Solutions:**

1. **Check connected monitors:**
   ```bash
   hyprctl monitors
   ```

2. **Configure monitors in home.nix:**
   ```nix
   wayland.windowManager.hyprland.settings.monitor = [
     "DP-1,1920x1080@60,0x0,1"
     "HDMI-A-1,disable"
   ];
   ```

3. **Force a resolution:**
   ```bash
   wlr-randr --output DP-1 --mode 1920x1080@60
   ```

### SDDM Login Issues

**Symptom**: Can't login or SDDM crashes

**Solutions:**

1. **Check SDDM logs:**
   ```bash
   sudo journalctl -u display-manager
   ```

2. **Try console login:**
   Press Ctrl+Alt+F2 to switch to TTY

3. **Disable SDDM temporarily:**
   ```nix
   services.xserver.displayManager.sddm.enable = false;
   ```

### Waybar Not Showing

**Symptom**: Waybar missing or crashes

**Solutions:**

1. **Start Waybar manually:**
   ```bash
   waybar
   ```

2. **Check Waybar config:**
   ```bash
   waybar --config ~/.config/waybar/config --style ~/.config/waybar/style.css
   ```

3. **View errors:**
   ```bash
   journalctl --user -u waybar
   ```

## Hardware Issues

### Audio Not Working

**Symptom**: No sound output

**Solutions:**

1. **Check Pipewire status:**
   ```bash
   systemctl --user status pipewire pipewire-pulse wireplumber
   ```

2. **Restart audio services:**
   ```bash
   systemctl --user restart pipewire pipewire-pulse wireplumber
   ```

3. **Check audio devices:**
   ```bash
   pactl list sinks
   wpctl status
   ```

4. **Select correct output:**
   ```bash
   wpctl set-default SINK_ID
   ```

5. **Test audio:**
   ```bash
   speaker-test -c 2
   ```

### GPU Not Recognized

**Symptom**: Graphics performance poor or GPU not detected

**AMD Solutions:**

1. **Check AMD GPU:**
   ```bash
   lspci | grep -i vga
   rocminfo
   rocm-smi
   ```

2. **Verify ROCm loaded:**
   ```bash
   lsmod | grep amdgpu
   ```

3. **Check GPU access:**
   ```bash
   groups | grep -E 'render|video'
   ```

**NVIDIA Solutions:**

1. **Check NVIDIA driver:**
   ```bash
   nvidia-smi
   ```

2. **Rebuild with NVIDIA enabled:**
   ```nix
   mySystem.hardware.nvidia = true;
   mySystem.hardware.amd = false;
   ```

### Bluetooth Not Working

**Symptom**: Can't connect Bluetooth devices

**Solutions:**

1. **Check Bluetooth service:**
   ```bash
   systemctl status bluetooth
   ```

2. **Enable Bluetooth:**
   ```bash
   sudo systemctl start bluetooth
   sudo systemctl enable bluetooth
   ```

3. **Check Bluetooth hardware:**
   ```bash
   lsusb | grep -i bluetooth
   rfkill list
   ```

4. **Unblock if blocked:**
   ```bash
   rfkill unblock bluetooth
   ```

5. **Use bluetui:**
   ```bash
   bluetui
   ```

## Service Issues

### Service Fails to Start

**Symptom**: Service in failed state

**Solutions:**

1. **Check service status:**
   ```bash
   systemctl status service-name
   sudo systemctl status service-name  # For system services
   systemctl --user status service-name  # For user services
   ```

2. **View service logs:**
   ```bash
   journalctl -u service-name -n 50
   sudo journalctl -u service-name --since "1 hour ago"
   ```

3. **Restart service:**
   ```bash
   sudo systemctl restart service-name
   systemctl --user restart service-name
   ```

4. **Check service dependencies:**
   ```bash
   systemctl list-dependencies service-name
   ```

### Permission Denied Errors

**Symptom**: Service can't access files or resources

**Solutions:**

1. **Check file permissions:**
   ```bash
   ls -la /path/to/file
   ```

2. **Add user to required groups:**
   ```nix
   mySystem.user.extraGroups = [
     "wheel"
     "networkmanager"
     "docker"
     "libvirtd"
     # Add necessary groups
   ];
   ```

3. **Rebuild and relogin:**
   ```bash
   sudo nixos-rebuild switch --flake .#YourConfig
   # Then logout and login
   ```

## YubiKey Issues

### YubiKey Not Detected

**Symptom**: System doesn't recognize YubiKey

**Solutions:**

1. **Check USB connection:**
   ```bash
   lsusb | grep Yubikey
   ```

2. **Check pcscd service:**
   ```bash
   systemctl status pcscd
   sudo systemctl start pcscd
   ```

3. **Test YubiKey:**
   ```bash
   ykman list
   ykman info
   ```

### YubiKey Authentication Not Working

**Symptom**: Can't authenticate with YubiKey

**Solutions:**

1. **Register YubiKey:**
   ```bash
   mkdir -p ~/.config/Yubico
   pamu2fcfg > ~/.config/Yubico/u2f_keys
   ```

2. **Check key file permissions:**
   ```bash
   chmod 600 ~/.config/Yubico/u2f_keys
   ls -la ~/.config/Yubico/u2f_keys
   ```

3. **Test authentication:**
   ```bash
   sudo echo "test"  # Should require YubiKey touch
   ```

4. **Check PAM configuration:**
   ```bash
   cat /etc/pam.d/sudo
   cat /etc/pam.d/login
   ```

### YubiKey Auto-login Not Working

**Symptom**: System doesn't auto-login with YubiKey

**Solutions:**

1. **Check auto-login services:**
   ```bash
   sudo systemctl status yubikey-autologin-init
   sudo systemctl status yubikey-autologin-monitor
   ```

2. **View logs:**
   ```bash
   sudo journalctl -u yubikey-autologin-init
   sudo journalctl -u yubikey-autologin-monitor
   ```

3. **Restart services:**
   ```bash
   sudo systemctl restart yubikey-autologin-init
   sudo systemctl restart yubikey-autologin-monitor
   ```

## AI Assistant Issues

### Ollama Service Not Starting

**Symptom**: Ollama service fails

**Solutions:**

1. **Check service status:**
   ```bash
   systemctl --user status ollama
   ```

2. **View logs:**
   ```bash
   journalctl --user -u ollama -f
   ```

3. **Restart service:**
   ```bash
   systemctl --user restart ollama
   ```

4. **Check port availability:**
   ```bash
   ss -tulpn | grep 11434
   ```

5. **Test manually:**
   ```bash
   ollama serve
   ```

### Open WebUI Not Accessible

**Symptom**: Can't access Web UI at localhost:8080

**Solutions:**

1. **Check service:**
   ```bash
   systemctl --user status open-webui
   ```

2. **Check port:**
   ```bash
   ss -tulpn | grep 8080
   ```

3. **Try accessing:**
   ```bash
   curl http://localhost:8080
   ```

4. **Restart service:**
   ```bash
   systemctl --user restart open-webui
   ```

### Model Not Loading

**Symptom**: AI model fails to load

**Solutions:**

1. **Check available models:**
   ```bash
   ollama list
   ```

2. **Pull model:**
   ```bash
   ollama pull llama2
   ```

3. **Deploy custom models:**
   ```bash
   deploy-ai-models
   ```

4. **Check disk space:**
   ```bash
   df -h ~/.ollama
   ```

5. **Check GPU access (AMD):**
   ```bash
   rocm-smi
   groups | grep -E 'render|video'
   ```

### AMD GPU Not Used by Ollama

**Symptom**: Ollama not using GPU acceleration

**Solutions:**

1. **Check ROCm:**
   ```bash
   rocminfo
   echo $HSA_OVERRIDE_GFX_VERSION
   ```

2. **Check service environment:**
   ```bash
   systemctl --user show ollama | grep Environment
   ```

3. **Verify GPU device files:**
   ```bash
   ls -la /dev/kfd /dev/dri/render*
   ```

## Network Issues

### No Internet Connection

**Symptom**: Can't connect to internet

**Solutions:**

1. **Check network status:**
   ```bash
   nmcli device status
   ip addr show
   ```

2. **Restart NetworkManager:**
   ```bash
   sudo systemctl restart NetworkManager
   ```

3. **Check DNS:**
   ```bash
   cat /etc/resolv.conf
   ping 8.8.8.8
   ```

4. **Test connectivity:**
   ```bash
   ping nixos.org
   curl -I https://google.com
   ```

### Firewall Blocking Connection

**Symptom**: Can't access services or ports

**Solutions:**

1. **Check firewall:**
   ```bash
   sudo nft list ruleset
   ```

2. **Temporarily disable firewall for testing:**
   ```bash
   sudo systemctl stop nftables
   # Test your connection
   sudo systemctl start nftables
   ```

3. **Open required ports in configuration:**
   ```nix
   # In modules/security/firewall.nix
   networking.firewall.allowedTCPPorts = [ your-port ];
   ```

### SSH Connection Refused

**Symptom**: Can't SSH into system

**Solutions:**

1. **Check SSH service:**
   ```bash
   sudo systemctl status sshd
   ```

2. **Remember custom port:**
   ```bash
   ssh -p 2222 user@host
   ```

3. **Check firewall:**
   ```bash
   sudo ss -tulpn | grep 2222
   ```

## General Debugging

### View System Logs

```bash
# All logs
journalctl -xe

# Since last boot
journalctl -b

# Specific service
journalctl -u service-name

# Follow logs in real-time
journalctl -f

# User services
journalctl --user -u service-name
```

### Check System Status

```bash
# Failed services
systemctl --failed
systemctl --user --failed

# System load
htop
top

# Disk usage
df -h
du -sh /*

# Memory usage
free -h
```

### Rebuild With Verbose Output

```bash
# Show detailed build info
sudo nixos-rebuild switch --flake .#YourConfig --show-trace --verbose
```

### Rollback Changes

```bash
# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# List generations
nix-env --list-generations --profile /nix/var/nix/profiles/system

# Boot into specific generation
sudo nixos-rebuild switch --rollback --to 123
```

### Recovery Mode

If system is completely broken:

1. **Boot from NixOS installer USB**

2. **Mount your system:**
   ```bash
   sudo mount /dev/sdXY /mnt
   sudo mount /dev/sdXZ /mnt/boot  # if separate
   ```

3. **Enter chroot:**
   ```bash
   sudo nixos-enter --root /mnt
   ```

4. **Fix and rebuild:**
   ```bash
   cd /home/username/dotfiles
   sudo nixos-rebuild switch --flake .#Stub
   ```

5. **Reboot:**
   ```bash
   exit
   sudo reboot
   ```

## Getting More Help

If issues persist:

1. **Check NixOS Manual**: https://nixos.org/manual/nixos/stable/
2. **Search NixOS Discourse**: https://discourse.nixos.org/
3. **NixOS Wiki**: https://nixos.wiki/
4. **GitHub Issues**: https://github.com/weegs710/AnomalOS/issues
5. **NixOS Matrix Chat**: https://matrix.to/#/#community:nixos.org

### Reporting Issues

When reporting issues, include:

- Configuration name (Rig/Hack/Guard/Stub)
- Hardware details (CPU, GPU, etc.)
- Relevant logs (`journalctl` output)
- Steps to reproduce
- Error messages
- What you've already tried

---

**Remember**: Always test configuration changes before applying permanently, and keep backups of working configurations.
