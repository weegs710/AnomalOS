# Secrets

Secret management via [agenix](https://github.com/ryantm/agenix). Secrets are encrypted with your SSH keys, committed to git encrypted, and decrypted to `/run/agenix/` (tmpfs) at boot — gone on reboot.

## How it works

- Encrypted `.age` files live in `secrets/` and are safe to commit
- SSH keys in `modules/nixos-modules/secrets.nix` control who can decrypt what
- At boot, agenix decrypts to `/run/agenix/`
- Uses existing SSH keys, including YubiKey-backed ones

## Key declarations

`modules/nixos-modules/secrets.nix` has the public keys:

```nix
let
  weegs  = "ssh-ed25519 AAAA... weegs@HX99G";   # User key
  HX99G  = "ssh-ed25519 AAAA... root@nixos";    # System host key
  users  = [weegs];
  systems = [HX99G];
  allKeys = users ++ systems;
in {
  # Add secret definitions here:
  # "secrets/example.age".publicKeys = allKeys;
}
```

No secrets are configured yet. Add the public key mapping here when you add one.

## Creating a secret

```bash
cd ~/dotfiles

# Create/edit the secret (opens $EDITOR)
nix run github:ryantm/agenix -- -e secrets/my-secret.age

# Type your secret, save, exit. The .age file is encrypted.

# Force-add it (secrets/ is in .gitignore as defense in depth)
git add -f secrets/my-secret.age
git commit -m "Add my-secret"
```

## Using a secret in config

```nix
# Declare it in the relevant module:
age.secrets.my-secret = {
  file = ./secrets/my-secret.age;
  owner = "weegs";
  mode = "400";
};

# Reference the decrypted path:
programs.something.passwordFile = config.age.secrets.my-secret.path;
# Resolves to: /run/agenix/my-secret
```

## Edit existing secret

```bash
nix run github:ryantm/agenix -- -e secrets/my-secret.age
# Make changes, save, exit
```

## Rekey (after changing SSH keys)

```bash
nix run github:ryantm/agenix -- -r
```

## Adding a new machine

```bash
# 1. Get the new machine's host key
sudo cat /etc/ssh/ssh_host_ed25519_key.pub

# 2. Add it to modules/nixos-modules/secrets.nix in the systems list

# 3. Rekey all secrets
nix run github:ryantm/agenix -- -r

# 4. Commit
git add modules/nixos-modules/secrets.nix
git add -f secrets/*.age
git commit -m "Add new machine to secrets"
```

## Why git add -f?

`.gitignore` blocks `secrets/` by default — prevents accidentally committing unencrypted files. `.age` files are encrypted and safe, but you have to explicitly add them with `-f`. This forces you to consciously add a secret, not accidentally sweep one in with `git add .`.

## Troubleshooting

**Secret not decrypting:**
```bash
ssh-add -L                                                # Check loaded keys
nix run github:ryantm/agenix -- -d secrets/my-secret.age  # Try manual decrypt
```

**Permission denied on /run/agenix:**
```bash
ls -la /run/agenix/
grep -r "age.secrets" ~/dotfiles/modules/   # Check declaration exists
```

**YubiKey issues with agenix:**
YubiKey-backed SSH keys work for system decryption at boot, but CLI operations (creating/editing secrets) can be finicky. If agenix hangs, try using a regular SSH key for that operation.
