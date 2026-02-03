# Troubleshooting

When stuff breaks.

## Build failures

```bash
# Clean and retry
sudo nix-collect-garbage -d
nix flake update
nrt-rig

# Hash mismatch? Update the specific input:
nix flake lock --update-input nixpkgs

# Clear eval cache:
rm -rf ~/.cache/nix

# Check disk space (need at least 10GB free):
df -h

# Check internet:
ping nixos.org
curl -I https://cache.nixos.org
```

## Boot problems

**Won't boot:** Select previous generation from boot menu. That's what they're there for.

**Hangs during boot:**
```nix
# Add to boot.nix temporarily:
boot.kernelParams = [ "debug" "verbose" ];
```
Then check `systemctl list-jobs` and `systemctl --failed`.

**Kernel panic:** Try the generic kernel temporarily:
```nix
boot.kernelPackages = pkgs.linuxPackages;
```
Check kernel logs with `journalctl -k`.

## Desktop

**Hyprland won't start:**
```bash
cat /tmp/hypr/$(ls -t /tmp/hypr/ | head -1)/hyprland.log
echo $XDG_SESSION_TYPE          # Should be "wayland"
lspci -k | grep -A 3 -i vga    # GPU drivers loaded?
```

**Wrong resolution:**
```bash
hyprctl monitors    # See what Hyprland sees
```
Edit the monitor line in `modules/hjem/hyprland.nix`.

**Ly won't log in:**
```bash
sudo journalctl -u ly
# Ctrl+Alt+F2 gets you to a TTY as fallback
```

**Noctalia missing:**
```bash
systemctl --user status noctalia
journalctl --user -u noctalia
systemctl --user restart noctalia
```

## Audio

```bash
systemctl --user status pipewire pipewire-pulse wireplumber
systemctl --user restart pipewire pipewire-pulse wireplumber

pactl list sinks          # See audio outputs
wpctl status              # WirePlumber status
wpctl set-default SINK_ID # Pick an output
```

## GPU

**AMD:**
```bash
lspci | grep -i vga
lsmod | grep amdgpu
rocm-smi                            # ROCm status
groups | grep -E 'render|video'     # GPU group access
```

## Bluetooth

```bash
systemctl status bluetooth
rfkill list               # Blocked?
rfkill unblock bluetooth  # Unblock if needed
lsusb | grep -i bluetooth
```

## YubiKey

**Not detected:**
```bash
lsusb | grep -i yubico
systemctl status pcscd
ykman list
```

**Auth not working:**
```bash
# Re-register:
mkdir -p ~/.config/Yubico
pamu2fcfg > ~/.config/Yubico/u2f_keys
chmod 600 ~/.config/Yubico/u2f_keys

# Test:
sudo echo "test"    # Should require touch
```

**Auto-login not working:**
```bash
sudo systemctl status yubikey-autologin-init
sudo systemctl status yubikey-autologin-monitor
sudo journalctl -u yubikey-autologin-init
```

## Network

```bash
nmcli device status
ip addr show

# DNS issues:
cat /etc/resolv.conf
ping 8.8.8.8    # Bypasses DNS

# Restart NetworkManager:
sudo systemctl restart NetworkManager
```

**SSH refused:** SSH is on port 2222.
```bash
ssh -p 2222 user@host
sudo ss -tulpn | grep 2222
```

**Firewall blocking something:**
```bash
sudo nft list ruleset
# To test without firewall temporarily:
sudo systemctl stop nftables
# ... test ...
sudo systemctl start nftables
```

## General debugging

```bash
journalctl -xe                    # Recent system logs
journalctl -b                     # Since last boot
journalctl -u service-name        # Specific service
journalctl --user -u service-name # User service
systemctl --failed                # Failed services
systemctl --user --failed         # Failed user services
```

**Verbose rebuild:**
```bash
nrt-rig -- --show-trace
```

## Recovery from USB

1. Boot NixOS installer USB
2. Mount your system:
```bash
sudo zpool import -f zroot
sudo mount -t zfs zroot/root /mnt
sudo mount /dev/nvme1n1p3 /mnt/boot   # adjust device
sudo mount -t zfs zroot/nix /mnt/nix
sudo mount -t zfs zroot/persist /mnt/persist
sudo mount -t zfs zroot/cache /mnt/cache
```
3. Fix and rebuild:
```bash
sudo nixos-rebuild switch --flake /mnt/home/weegs/dotfiles#nixosConfigurations.Rig
```
4. Reboot.

## Getting help

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Discourse](https://discourse.nixos.org/)
- [NixOS Wiki](https://nixos.wiki/)
- [GitHub Issues](https://github.com/weegs710/AnomalOS/issues)
- [Codeberg Issues](https://codeberg.org/weegs710/AnomalOS/issues)
