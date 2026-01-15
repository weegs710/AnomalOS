# Secret Management with Agenix

This configuration uses [agenix](https://github.com/ryantm/agenix) to securely manage secrets like passwords, API keys, and credentials.

## Overview

**How it works:**
- Secrets are encrypted using SSH keys (the same ones you use for git/ssh)
- Encrypted secrets are stored in `secrets/` directory and committed to git
- At boot time, agenix decrypts secrets to `/run/agenix/` (tmpfs, cleared on reboot)
- Only authorized SSH keys can decrypt secrets

**Benefits:**
- Secrets encrypted in git
- Per-user and per-host access control
- Uses existing SSH keys (including YubiKey-backed keys)
- Automatic decryption at boot
- Secrets stored in memory only (/run is tmpfs)

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

Create an example secret:

```bash
cd ~/dotfiles

# Create/edit the secret (opens your $EDITOR)
nix run github:ryantm/agenix -- -e secrets/example-secret.age

# In the editor, type your secret value, save and exit
```

The file `secrets/example-secret.age` is now encrypted and safe to commit!

### 4. Rebuild Your System

```bash
sudo nixos-rebuild switch --flake .#Rig
```

Agenix will decrypt secrets at boot to `/run/agenix/`.

### 5. Verify Secret is Available

```bash
# Check secrets were decrypted
ls -la /run/agenix/
# Should show your secrets (mode 400, owner weegs)
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
# Edit existing secret
nix run github:ryantm/agenix -- -e secrets/my-secret.age

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
nix run github:ryantm/agenix -- -e secrets/database-password.age
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

# Example: Use in a backup service or SSH config
programs.ssh.matchBlocks."backup-server" = {
  identityFile = config.age.secrets.backup-ssh-key.path;
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

No secrets are currently configured in this repository.

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
nix run github:ryantm/agenix -- -d secrets/my-secret.age
# Should decrypt and show your secret value
```

### 3. Backup Secrets Responsibly

```bash
# Encrypted secrets in git - safe
git add secrets/*.age

# Decrypted secrets - NEVER commit
# Already in .gitignore:
# secrets/*.txt
# secrets/*.key
```

### 4. Rotate Secrets Regularly

```bash
# Every 6-12 months, rotate important secrets
nix run github:ryantm/agenix -- -e secrets/my-secret.age
# Change password/secret, save

# Rebuild system to apply changes
sudo nixos-rebuild switch --flake .#Rig
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
ls -la ~/dotfiles/secrets/my-secret.age

# Check SSH key can decrypt
ssh-add -L  # List loaded SSH keys
nix run github:ryantm/agenix -- -d secrets/my-secret.age
```

### Permission Denied

```bash
# Check /run/agenix permissions
ls -la /run/agenix/

# Check secret configuration in your modules
grep -r "age.secrets" ~/dotfiles/modules/
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

### Git Refusing to Add Encrypted Secrets

If git refuses to add `.age` files even though they're encrypted:

```bash
# Error you might see:
$ git add secrets/my-secret.age
The following paths are ignored by one of your .gitignore files:
secrets/

# Solution: Force add the encrypted file
git add -f secrets/my-secret.age

# Verify it was added
git status
```

**Why this happens:**

The `.gitignore` includes `secrets/` and `*.age` patterns as **defense in depth** - to prevent accidentally committing unencrypted secrets. However, agenix-encrypted `.age` files are safe to commit.

**Defense in depth approach:**
- `.gitignore` blocks all secrets by default (prevents accidents)
- Use `git add -f` to explicitly add encrypted secrets (requires intention)
- This extra step ensures you're consciously adding secrets to git

**Automated workflow:**

```bash
# After creating/editing a secret
cd ~/dotfiles

# Verify it's encrypted
file secrets/my-secret.age
# Output: secrets/my-secret.age: data

# Force add the encrypted file
git add -f secrets/my-secret.age

# Commit with descriptive message
git commit -m "Update my-secret"

# Push to remote
git push
```

**What NOT to do:**

```bash
# DO NOT modify .gitignore to allow *.age files
# This defeats the defense in depth approach

# DO NOT use git add . or git add secrets/
# These won't work due to .gitignore and don't show clear intent
```

## Further Usage

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
# Example script to rotate a secret
#!/usr/bin/env bash
set -euo pipefail

NEW_SECRET=$(openssl rand -base64 32)
cd ~/dotfiles

# Update secret (interactive, opens editor)
# You would paste NEW_SECRET into the editor
nix run github:ryantm/agenix -- -e secrets/my-secret.age

# Rebuild system
sudo nixos-rebuild switch --flake .#Rig

echo "Secret rotated successfully"
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

- Secrets encrypted at rest (in git)
- Secrets encrypted in transit (SSH)
- Secrets only in memory at runtime (/run is tmpfs)
- Automatic cleanup on reboot
- SSH key-based access control

### What's Not Protected

- Secrets in memory (while system running)
- Processes with root access can read secrets
- Physical access to running system
- Compromised SSH private keys

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
cd ~/dotfiles
nix run github:ryantm/agenix -- -e secrets/my-secret.age
# In editor, paste your plaintext secret, save and exit

# 2. Update configuration to use agenix
# Add to configuration.nix or relevant module:
# age.secrets.my-secret = {
#   file = ./secrets/my-secret.age;
#   owner = "weegs";
# };

# 3. Rebuild system
sudo nixos-rebuild switch --flake .#Rig

# 4. Remove plaintext version
sudo shred -u /path/to/old/plaintext-secret

# 5. Verify secret is available
ls -la /run/agenix/my-secret
```

## References

- [Agenix GitHub](https://github.com/ryantm/agenix)
- [Agenix Tutorial](https://github.com/ryantm/agenix#tutorial)
- [Age Encryption](https://age-encryption.org/)
- [NixOS Wiki: Secrets](https://nixos.wiki/wiki/Agenix)
