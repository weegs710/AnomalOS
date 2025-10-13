# Maintenance Guide

## Overview

This guide covers routine maintenance tasks, update procedures, and best practices for keeping your NixOS system healthy and up-to-date.

## Update Schedule

### Recommended Update Frequency

| Component | Frequency | Command | Notes |
|-----------|-----------|---------|-------|
| **System Packages** | Weekly | `update && nrs-rig` | Updates flake inputs |
| **Garbage Collection** | Weekly | `recycle` | Removes old generations (7+ days) |
| **Backup Verification** | Monthly | See [BACKUP.md](BACKUP.md) | Verify backups work |
| **Security Updates** | As needed | Check [NixOS Security](https://nixos.org/manual/nixos/stable/index.html#sec-security-updates) | Critical patches |
| **Full System Upgrade** | Monthly | `nix flake update` | Major package updates |

### Automated Maintenance

Some maintenance tasks run automatically:

- **Backups**: Daily at midnight (`restic-backups-localbackup.timer`)
- **Garbage Collection**: Daily, removes >90 day old generations
- **Store Optimization**: Automatic during garbage collection

## Update Procedures

### Quick Update (Recommended)

Use the convenient update scripts that test before switching:

```bash
# For Rig configuration
rig-up

# For other configurations
hack-up
guard-up
stub-up
```

These scripts:
1. Update flake inputs
2. Test the new configuration
3. Prompt for confirmation before switching
4. Only switch if test succeeds

### Manual Update Process

If you prefer manual control:

```bash
# 1. Update flake inputs
cd ~/dotfiles
nix flake update

# 2. Review changes (optional)
nix flake metadata

# 3. Test new configuration
sudo nixos-rebuild test --flake .#Rig

# 4. If test succeeds, switch
sudo nixos-rebuild switch --flake .#Rig
```

### Selective Updates

Update specific inputs only:

```bash
# Update single input
nix flake lock --update-input nixpkgs

# Update home-manager only
nix flake lock --update-input home-manager

# Update cachyos packages
nix flake lock --update-input cachyos
```

## Garbage Collection

### Automatic Garbage Collection

The system automatically removes old generations daily:

```nix
# In modules/core/nix.nix
nix.gc = {
  automatic = true;
  dates = "daily";
  options = "--delete-older-than 90d";
};
```

### Manual Garbage Collection

```bash
# Remove old generations (7+ days)
recycle

# Or manually with custom age
sudo nix-collect-garbage --delete-older-than 14d

# Aggressive cleanup (removes everything except current)
sudo nix-collect-garbage -d

# Check space savings
df -h /nix
```

### Cleaning User Profiles

```bash
# List generations
nix profile history

# Remove specific generation
nix profile remove <generation-number>

# Remove all old generations
nix profile wipe-history
```

## System Health Monitoring

### Check System Status

```bash
# View recent system logs
sudo journalctl -xe

# Check failed services
systemctl --failed

# View specific service status
systemctl status <service-name>

# Check user services
systemctl --user status
```

### Disk Space Management

```bash
# Check overall disk usage
df -h

# Check Nix store size
du -sh /nix/store

# Find largest store paths
nix path-info --recursive --size --store auto --all |
  sort -nk2 | tail -20

# Check specific configuration size
nix path-info --size --closure-size --store auto /run/current-system
```

### Package Information

```bash
# List installed packages
nix-env -qa

# Search for package
nix search nixpkgs <package-name>

# Get package info
nix search nixpkgs <package-name> --json | jq

# Check why package is in system
nix why-depends /run/current-system /nix/store/<package-hash>
```

## Configuration Management

### Version Control Best Practices

```bash
# Always commit changes
cd ~/dotfiles
git status
git diff
git add <files>
git commit -m "Description of changes"
git push

# Create backup branch before major changes
git checkout -b backup-$(date +%Y%m%d)
git checkout main
```

### Testing Changes

```bash
# Always test before switching
sudo nixos-rebuild test --flake .#Rig

# Test will:
# - Build new configuration
# - Activate it temporarily
# - NOT update bootloader
# - Revert on reboot if system crashes
```

### Rolling Back

```bash
# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Switch to previous generation (from bootloader)
# - Reboot
# - Select previous generation in boot menu

# Or rollback programmatically
sudo nixos-rebuild switch --rollback

# Switch to specific generation
sudo nixos-rebuild switch --flake .#Rig --profile-name <generation>
```

## Troubleshooting Common Issues

### Build Failures After Update

```bash
# Clear build cache
sudo nix-collect-garbage -d

# Update flake inputs
nix flake update

# Retry build
sudo nixos-rebuild test --flake .#Rig

# If still failing, check build logs
nix log /nix/store/<failed-derivation>
```

### Service Failures

```bash
# Check service status
systemctl status <service-name>

# View service logs
sudo journalctl -u <service-name> -n 50

# Restart service
sudo systemctl restart <service-name>

# Check service configuration
systemctl cat <service-name>
```

### Disk Space Issues

```bash
# Emergency cleanup
sudo nix-collect-garbage -d
sudo nix-store --optimize

# Check what's using space
ncdu /nix/store

# Clear system logs
sudo journalctl --vacuum-time=7d
```

## Changelog Tracking

### Viewing System Changes

```bash
# Compare current vs previous generation
nix store diff-closures \
  /nix/var/nix/profiles/system-{$(($(readlink /nix/var/nix/profiles/system | grep -oP '\d+')-1)),$(readlink /nix/var/nix/profiles/system | grep -oP '\d+')}-link

# View flake inputs changes
nix flake metadata --json | jq '.locks.nodes'

# Git log for configuration changes
cd ~/dotfiles
git log --oneline -n 20
```

### Keeping a Manual Changelog

Create `CHANGELOG.md` in your dotfiles:

```markdown
# Changelog

## 2025-01-13
- Added hyprland configuration consolidation
- Improved backup documentation
- Enhanced profiles with better comments

## 2025-01-12
- Integrated agenix for secret management
- Enhanced .gitignore for better security
- Moved binary files out of repo
```

## Security Maintenance

### Security Updates

```bash
# Check for security advisories
# Visit: https://nixos.org/manual/nixos/stable/index.html#sec-security-updates

# Update immediately for security patches
nix flake lock --update-input nixpkgs
sudo nixos-rebuild switch --flake .#Rig
```

### YubiKey Maintenance

```bash
# Test YubiKey authentication
sudo echo "Testing YubiKey"
# Should require YubiKey touch

# Re-register YubiKey if needed
pamu2fcfg > ~/.config/Yubico/u2f_keys

# Check YubiKey services
systemctl status yubikey-autologin-init
sudo journalctl -u yubikey-autologin-init
```

### Secret Management

```bash
# Rotate secrets periodically
cd ~/dotfiles
agenix -e secrets/restic-password.age

# Verify secret decryption
cat /run/agenix/restic-password

# Re-encrypt secrets with new keys
agenix -r
```

## Performance Optimization

### Store Optimization

```bash
# Optimize Nix store (deduplicates files)
sudo nix-store --optimize

# Check optimization results
nix store optimise --dry-run
```

### Build Optimization

Already configured in `modules/core/nix.nix`:

```nix
nix.settings = {
  cores = 0;              # Use all cores
  max-jobs = "auto";      # Parallel builds
  auto-optimise-store = true;
};
```

### Cache Configuration

Binary caches are pre-configured:

```nix
substituters = [
  "https://nix-community.cachix.org"
  "https://hyprland.cachix.org"
  "https://cuda-maintainers.cachix.org"
];
```

## Backup Maintenance

See [BACKUP.md](BACKUP.md) for comprehensive backup procedures.

### Quick Backup Check

```bash
# Verify backup service is running
systemctl status restic-backups-localbackup.timer

# View recent backup logs
sudo journalctl -u restic-backups-localbackup.service -n 50

# List recent snapshots
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password snapshots

# Test restore (monthly recommended)
sudo restic -r /backup/restic-repo --password-file /run/agenix/restic-password restore latest \
  --target /tmp/restore-test --include /home/weegs/dotfiles/README.md
```

## Monthly Maintenance Checklist

**Day 1 of each month:**

- [ ] Update system: `rig-up`
- [ ] Test backups: Restore a few files to verify
- [ ] Check disk space: `df -h`
- [ ] Review failed services: `systemctl --failed`
- [ ] Check security advisories
- [ ] Rotate any sensitive secrets (if policy requires)
- [ ] Review system logs for anomalies
- [ ] Update documentation if configuration changed
- [ ] Commit and push dotfiles changes

**Optional (quarterly):**

- [ ] Review and update `.gitignore`
- [ ] Audit installed packages for unused ones
- [ ] Review and optimize startup services
- [ ] Check for deprecated NixOS options
- [ ] Update hardware configuration if hardware changed

## Emergency Procedures

### System Won't Boot

1. **Select previous generation** from bootloader menu
2. **Boot into recovery** and rollback:
   ```bash
   sudo nixos-rebuild switch --rollback
   ```
3. **Boot from USB** and repair (see INSTALLATION.md)

### Configuration Broke System

```bash
# Revert to last working configuration
cd ~/dotfiles
git log --oneline
git checkout <last-working-commit>
sudo nixos-rebuild switch --flake .#Rig
```

### Lost SSH Access (YubiKey Issues)

1. Boot into single-user mode (bootloader)
2. Disable YubiKey in configuration.nix:
   ```nix
   mySystem.features.yubikey = false;
   ```
3. Rebuild and reboot

## Best Practices

1. **Always test before switching**: Use `nixos-rebuild test` first
2. **Keep git history clean**: Meaningful commit messages
3. **Regular backups**: Verify backups work monthly
4. **Update regularly**: Weekly updates prevent massive changes
5. **Document changes**: Update docs when modifying configuration
6. **Use version control**: Commit before major changes
7. **Monitor disk space**: Clean up old generations regularly
8. **Check logs**: Review system logs for issues
9. **Security first**: Update promptly for security patches
10. **Test restores**: Monthly backup restore tests

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [NixOS Wiki](https://nixos.wiki/)
- [NixOS Discourse](https://discourse.nixos.org/)
- [Nix Package Search](https://search.nixos.org/)

## Quick Reference

```bash
# Update system
rig-up

# Clean old generations
recycle

# Test configuration
sudo nixos-rebuild test --flake .#Rig

# Switch configuration
sudo nixos-rebuild switch --flake .#Rig

# Check system status
systemctl --failed

# View logs
sudo journalctl -xe

# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Optimize store
sudo nix-store --optimize

# Check disk usage
df -h /nix
```
