# Secrets

Secret management is [agenix](https://github.com/ryantm/agenix). Secrets are encrypted to post-quantum age recipients (ML-KEM-768 + X25519 hybrids), committed encrypted, and decrypted to `/run/agenix/` at boot, which is a tmpfs, so they are gone again on reboot.

## Layout

| Path                                         | Job                                                                                |
| -------------------------------------------- | ---------------------------------------------------------------------------------- |
| `secrets/*.age`                              | the encrypted files, safe to commit                                                |
| `secrets/agenix-rules.nix`                   | maps each `.age` filename to its recipients, which is what agenix reads            |
| `secrets/recipients/*.pub`                   | one public recipient per file: each YubiKey, and each host                         |
| `modules/system-level/security/secrets.nix` | sets the identity and declares the fleet-wide secrets via `age.secrets.*`          |
| `/run/agenix/<name>`                         | where each one decrypts to                                                         |

The security module declares the three every host needs (Tailscale's auth key, the XMPP password and the GitHub token). A secret one service uses is declared in that service's module, like `searx-secret-key` in `searx.nix` and the arr API keys in the media-server modules -- `age.secrets` is a normal option and any module may set it.

## Who Can Decrypt

Every file is encrypted to the same three recipients:

- `weegs-main` and `weegs-backup` -- one per YubiKey, made with `age-plugin-fido2-hmac -pq -g`. Decrypting needs that key plugged in, its PIN and a touch.
- `HX99G` -- the host's own age key, which is what decrypts at boot.

age refuses to mix post-quantum and classic recipients in one file, so an SSH key cannot be a recipient anymore. Either YubiKey alone, or the host key alone, opens every secret.

## The Identity Is the Host's Age Key

```nix
age.identityPaths = [ "/persist/etc/age/host.key" ];
```

It reads this from `/persist` directly rather than through `/etc`, because the bind mount gets removed during activation on a tmpfs root. The key is root-only, `0400`, made with `age-keygen -pq`.

If that key is missing for some reason or otherwise doesnt match, agenix will fail silently at boot -- so services depending on a secret stay down without it, rather than telling you why.

Adding a new machine needs a new key, so every secret ALSO needs a rekey. However, restoring `/persist` from a snapshot during installation is what avoids that, see [Installing](./install.md#restoring-persist).

## Creating a Secret

Add it to `secrets/agenix-rules.nix` first, or agenix has no recipients to encrypt to:

```nix
"my-secret.age".publicKeys = recipients;
```

Then, from `secrets/` (agenix finds `agenix-rules.nix` in the current directory or a parent):

```bash
cd ~/repo/public/anomalos/secrets
agenix -e my-secret.age -i ~/.config/age/fido2-main.txt     # opens $EDITOR
```

The agenix CLI only finds SSH keys on its own, so every `-e`, `-d` and `-r` needs the `-i` for whichever YubiKey is plugged in: `fido2-main.txt` for the main key, `fido2-backup.txt` for the backup. Pass the one that matches, not both.

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

The `agenix` CLI and `age-plugin-fido2-hmac` are installed as user packages by the security module.

## Adding a Machine

```bash
# 1. on the new machine, a post-quantum host key
sudo age-keygen -pq -o /persist/etc/age/host.key
sudo age-keygen -y /persist/etc/age/host.key        # the public half

# 2. save that as secrets/recipients/<HOST>.pub and add (key "<HOST>") to the recipients list

# 3. rekey everything against the new recipient list, from secrets/
agenix -r -i ~/.config/age/fido2-main.txt
```

Step 3 is NOT optional. A recipient added to `agenix-rules.nix` does nothing until the files are re-encrypted, and the new host will just boot with secrets it cannot read.

## Troubleshooting

```bash
agenix -d my-secret.age -i ~/.config/age/fido2-main.txt   # try decrypting by hand, from secrets/
sudo ls -la /run/agenix/                                 # what decrypted, and with what ownership
grep -rn "age.secrets" modules/                          # confirm the declaration exists
```

## What Never Goes In Here

`.gitignore` blocks `*.key`, `*.pem`, `*.secret`, `*-password`, `credentials.json`, `.env`, `id_rsa`, `id_ed25519`, `*.gpg` and `*.asc`. The `.age` files, `agenix-rules.nix` and `recipients/*.pub` are explicitly not ignored -- the first are encrypted and the rest are public keys only.

If a credential needs to exist on the machine it goes through agenix.
