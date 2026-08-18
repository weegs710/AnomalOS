# Secrets

Secret management is [agenix](https://github.com/ryantm/agenix). Secrets are encrypted with SSH keys, committed encrypted, and decrypted to `/run/agenix/` at boot, which is a tmpfs, so they are gone again on reboot.

## Layout

| Path                                         | Job                                                                                |
| -------------------------------------------- | ---------------------------------------------------------------------------------- |
| `secrets/*.age`                              | the encrypted files, safe to commit                                                |
| `secrets/secrets.nix`                        | maps each `.age` filename to its recipient public keys, which is what agenix reads |
| `modules/system-level/security/secrets.nix` | wires them into the system via `age.secrets.*`                                     |
| `/run/agenix/<name>`                         | where each one decrypts to                                                         |

Most are declared in the security module -- `age.secrets` is a normal option and any module may set it.

## The Identity Is the SSH Host Key

```nix
age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
```

It reads this from `/persist` directly rather than through `/etc`, because the bind mount gets removed during activation on a tmpfs root.

If that key is missing for some reason or otherwise doesnt match, agenix will fail silently at boot -- so services depending on a secret stay down without it, rather than telling you why.

Adding a new machine needs a new key, so every secret ALSO needs a rekey. However, restoring `/persist` from a snapshot during installation is what avoids that, see [Installing](./install.md#restoring-persist).

## Creating a Secret

Add it to `secrets/secrets.nix` first, or agenix has no recipients to encrypt to:

```nix
let
  weegs = "ssh-ed25519 AAAA... weegs@HX99G";
  HX99G = "ssh-ed25519 AAAA... root@HX99G";
in
{
  "my-secret.age".publicKeys = [ weegs HX99G ];
}
```

Then:

```bash
cd ~/repo/public/anomalos
agenix -e secrets/my-secret.age     # opens $EDITOR
```

Then just declare it in whichever module uses it:

```nix
age.secrets.my-secret = {
  file = ../../../secrets/my-secret.age;
  owner = "weegs";
  mode = "0400";
};

# reference the decrypted path, NEVER the .age file
programs.something.passwordFile = config.age.secrets.my-secret.path;
# resolves to /run/agenix/my-secret
```

The `agenix` CLI is installed as a user package by the security module. You can call it without it being installed: `nix run github:ryantm/agenix -- -e secrets/my-secret.age`.

## Adding a Machine

```bash
# 1. on the new machine
sudo cat /etc/ssh/ssh_host_ed25519_key.pub

# 2. add it to secrets/secrets.nix as a recipient

# 3. rekey everything against the new recipient list
agenix -r
```

Step 3 is NOT optional. A recipient added to `secrets.nix` does nothing until the files are re-encrypted, and the new host will just boot with secrets it cannot read.

## Troubleshooting

```bash
ssh-add -L                              # which keys are actually loaded
agenix -d secrets/my-secret.age         # try decrypting by hand
ls -la /run/agenix/                     # what decrypted, and with what ownership
grep -rn "age.secrets" modules/         # confirm the declaration exists
```

YubiKey-backed SSH keys work fine at boot, but creating or editing a secret interactively can be flaky. If agenix hangs, I just use a plain SSH key for the edit.

## What Never Goes In Here

`.gitignore` blocks `*.key`, `*.pem`, `*.secret`, `*-password`, `credentials.json`, `.env`, `id_rsa`, `id_ed25519`, `*.gpg` and `*.asc`. The `.age` files and `secrets.nix` are explicitly not ignored -- the first are encrypted and the second contains public keys only.

If a credential needs to exist on the machine it goes through agenix.
