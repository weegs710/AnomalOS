# Secret Management with Agenix

This configuration uses [agenix](https://github.com/ryantm/agenix) to securely manage secrets like passwords, API keys, and credentials.

## Overview

**How it works:**
- Secrets are encrypted using SSH keys (the same ones you use for git/ssh)
- Encrypted secrets are stored in `secrets/` directory and committed to git
- At boot time, agenix decrypts secrets to `/run/agenix/` (tmpfs, cleared on reboot)
- Only authorized SSH keys can decrypt secrets

**Benefits:**
- ✅ Secrets encrypted in git
- ✅ Per-user and per-host access control
- ✅ Uses existing SSH keys (including YubiKey-backed keys)
- ✅ Automatic decryption at boot
- ✅ Secrets stored in memory only (/run is tmpfs)

## Quick Start

### 1. Update Flake Lock

First, update your flake to download agenix:

```bash
cd ~/dotfiles
nix flake update
```

### 2. Check Your SSH Keys

Verify you have SSH keys available:

```bash
# User SSH key
cat ~/.ssh/id_ed25519.pub

# System host key
sudo cat /etc/ssh/ssh_host_ed25519_key.pub
```

These keys are already configured in `secrets.nix`.

### 3. Create Your First Secret

Create the restic backup password:

```bash
cd ~/dotfiles

# Create/edit the secret (opens your $EDITOR)
nix run github:ryantm/agenix -- -e secrets/restic-password.age

# In the editor, type your restic password, save and exit
# Example: openssl rand -base64 32 (run in another terminal to generate)
```

The file `secrets/restic-password.age` is now encrypted and safe to commit!

### 4. Rebuild Your System

```bash
sudo nixos-rebuild switch --flake .#Rig
```

Agenix will decrypt the secret at boot to `/run/agenix/restic-password`.

### 5. Verify Secret is Available

```bash
# Check secret was decrypted
ls -la /run/agenix/
# Should show: restic-password (mode 400, owner root)

# Test backup service can access it
sudo systemctl status restic-backups-localbackup
```

## Managing Secrets

### Create a New Secret

```bash
cd ~/dotfiles

# Add to secrets.nix
nano secrets.nix
# Add: "my-secret.age".publicKeys = allKeys;

# Create the encrypted secret
nix run github:ryantm/agenix -- -e secrets/my-secret.age

# Type your secret, save, exit
```

### Edit Existing Secret

```bash
# Edit restic password
nix run github:ryantm/agenix -- -e secrets/restic-password.age

# Make changes, save, exit
```

### Use Secret in Configuration

```nix
# In configuration.nix or any module

# 1. Declare the secret
age.secrets.my-secret = {
  file = ./secrets/my-secret.age;
  owner = "weegs";  # or "root"
  mode = "400";
};

# 2. Use the secret path
programs.example.passwordFile = config.age.secrets.my-secret.path;
# Points to: /run/agenix/my-secret
```

### Rekey Secrets (After Changing SSH Keys)

```bash
# If you change SSH keys in secrets.nix, rekey all secrets
nix run github:ryantm/agenix -- -r
```

## Adding New Machines/Users

### Add a New Machine

```bash
# 1. On new machine, get its host key
sudo cat /etc/ssh/ssh_host_ed25519_key.pub

# 2. In dotfiles, edit secrets.nix
nano secrets.nix
```

```nix
let
  # Add new system
  newSystem = "ssh-ed25519 AAAA... root@newsystem";

  systems = [ HX99G newSystem ];  # Add to list
```

```bash
# 3. Rekey all secrets to include new machine
nix run github:ryantm/agenix -- -r

# 4. Commit changes
git add secrets.nix secrets/*.age
git commit -m "Add newSystem to secrets"
```

### Add a New User

Same process as adding a machine, but add to the `users` list in `secrets.nix`.

## Secret Types & Examples

### Password Files

```bash
# Simple password
nix run github:ryantm/agenix -- -e secrets/restic-password.age
# Content: just the password, no newline

# Multi-line credentials
nix run github:ryantm/agenix -- -e secrets/aws-credentials.age
# Content:
# AWS_ACCESS_KEY_ID=AKIA...
# AWS_SECRET_ACCESS_KEY=...
```

### SSH Keys

```bash
# Encrypt SSH private key
nix run github:ryantm/agenix -- -e secrets/backup-ssh-key.age
# Paste private key contents
```

```nix
# Use in config
age.secrets.backup-ssh-key = {
  file = ./secrets/backup-ssh-key.age;
  mode = "600";
};

services.restic.backups.remote = {
  repository = "sftp:...";
  environmentFile = config.age.secrets.backup-ssh-key.path;
};
```

### API Keys

```bash
# Encrypt API key
nix run github:ryantm/agenix -- -e secrets/openai-key.age
# Content: sk-...
```

```nix
# Use in config
age.secrets.openai-key = {
  file = ./secrets/openai-key.age;
  owner = "weegs";
};

environment.sessionVariables = {
  OPENAI_API_KEY = "$(cat ${config.age.secrets.openai-key.path})";
};
```

## Current Secrets

| Secret | Used By | Description |
|--------|---------|-------------|
| `restic-password.age` | Restic backup service | Encrypts backup repository |

## Best Practices

### 1. Keep secrets.nix Updated

Always ensure `secrets.nix` has correct SSH keys:

```bash
# Verify your key matches
cat ~/.ssh/id_ed25519.pub
grep -A 1 "weegs =" ~/dotfiles/secrets.nix
```

### 2. Test Secrets After Creation

```bash
# After creating/editing a secret, test it
nix run github:ryantm/agenix -- -d secrets/restic-password.age
# Should decrypt and show your password
```

### 3. Backup Secrets Responsibly

```bash
# Encrypted secrets in git - safe ✓
git add secrets/*.age

# Decrypted secrets - NEVER commit ✗
# Already in .gitignore:
# secrets/*.txt
# secrets/*.key
```

### 4. Rotate Secrets Regularly

```bash
# Every 6-12 months, rotate important secrets
nix run github:ryantm/agenix -- -e secrets/restic-password.age
# Change password, save

# Update services using the secret
sudo systemctl restart restic-backups-localbackup
```

### 5. Use Appropriate Permissions

```nix
# Root-only secrets
age.secrets.system-secret = {
  mode = "400";  # r-------- root only
  owner = "root";
};

# User secrets
age.secrets.user-secret = {
  mode = "400";
  owner = "weegs";
};

# Group-readable (rare)
age.secrets.shared-secret = {
  mode = "440";  # r--r-----
  group = "admins";
};
```

## Troubleshooting

### Secret Not Decrypting

```bash
# Check if secret file exists
ls -la ~/dotfiles/secrets/restic-password.age

# Check SSH key can decrypt
ssh-add -L  # List loaded SSH keys
nix run github:ryantm/agenix -- -d secrets/restic-password.age
```

### Permission Denied

```bash
# Check /run/agenix permissions
ls -la /run/agenix/

# Check secret configuration
grep -A 3 "restic-password" ~/dotfiles/configuration.nix
```

### Wrong SSH Key

```bash
# Verify secrets.nix has correct key
cat ~/.ssh/id_ed25519.pub
cat ~/dotfiles/secrets.nix

# If mismatch, update secrets.nix and rekey
nix run github:ryantm/agenix -- -r
```

### YubiKey Issues

If using YubiKey-backed SSH keys:

```bash
# Ensure YubiKey is present
ykman list

# Check SSH agent has YubiKey key
ssh-add -L | grep -i cardno

# May need to use regular SSH key for agenix operations
# YubiKey keys work for system decryption, but CLI operations
# are easier with a regular key
```

## Advanced Usage

### Per-Secret SSH Keys

```nix
# In secrets.nix - give different keys access to different secrets
{
  # Admin-only secrets
  "root-password.age".publicKeys = [ adminUser HX99G ];

  # User secrets
  "user-config.age".publicKeys = [ weegs HX99G ];

  # Shared secrets
  "wifi-password.age".publicKeys = allKeys;
}
```

### Automatic Secret Updates

```bash
# Script to rotate restic password
#!/usr/bin/env bash
set -euo pipefail

NEW_PASSWORD=$(openssl rand -base64 32)
cd ~/dotfiles

# Update secret
echo "$NEW_PASSWORD" | nix run github:ryantm/agenix -- -e secrets/restic-password.age

# Rebuild system
sudo nixos-rebuild switch --flake .#Rig

# Restart service
sudo systemctl restart restic-backups-localbackup

echo "Restic password rotated successfully"
```

### Using Secrets in Home Manager

```nix
# In home.nix
home.file.".config/app/config".text = ''
  api_key = ${builtins.readFile config.age.secrets.api-key.path}
'';
```

## Security Considerations

### What's Protected

- ✅ Secrets encrypted at rest (in git)
- ✅ Secrets encrypted in transit (SSH)
- ✅ Secrets only in memory at runtime (/run is tmpfs)
- ✅ Automatic cleanup on reboot
- ✅ SSH key-based access control

### What's Not Protected

- ❌ Secrets in memory (while system running)
- ❌ Processes with root access can read secrets
- ❌ Physical access to running system
- ❌ Compromised SSH private keys

### Defense in Depth

1. **Encrypt disk**: Use LUKS for full-disk encryption
2. **Secure SSH keys**: Use strong passphrase or YubiKey
3. **Limit root access**: Use sudo, audit logs
4. **Regular rotation**: Change secrets periodically
5. **Monitor access**: Check /run/agenix access logs

## Migration from Plaintext

If you have existing plaintext secrets:

```bash
# 1. Create encrypted version
cat /etc/nixos/restic-password | \
  nix run github:ryantm/agenix -- -e secrets/restic-password.age

# 2. Update configuration to use agenix
# (already done in configuration.nix)

# 3. Rebuild system
sudo nixos-rebuild switch --flake .#Rig

# 4. Remove plaintext version
sudo shred -u /etc/nixos/restic-password

# 5. Verify service works
sudo systemctl status restic-backups-localbackup
```

## References

- [Agenix GitHub](https://github.com/ryantm/agenix)
- [Agenix Tutorial](https://github.com/ryantm/agenix#tutorial)
- [Age Encryption](https://age-encryption.org/)
- [NixOS Wiki: Secrets](https://nixos.wiki/wiki/Agenix)
