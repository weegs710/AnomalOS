# My NixOS Setup - anomalOS

> **Important**: This is a hobbyist project. I'm learning as I go. If something's broken or stupid, that's why. This config is designed for my machine and my workflow. It might work on your system, it might not. There are no guarantees. You're welcome to use the whole thing or just steal bits and pieces. It's all FOSS, so do whatever you want with it.

## What's in here

I run Hyprland on NixOS with a bunch of stuff I've cobbled together over time:

- **Desktop**: Hyprland compositor with Noctalia shell UI
- **Login**: Ly display manager (works with my YubiKey for login)
- **Shell**: Fish with Oh My Posh prompt
- **Editor**: Flow Control
- **Terminal**: Ghostty
- **Filesystem**: ZFS with automated snapshots
- **Security**: YubiKey for authentication, Suricata IDS, hardened firewall
- **Gaming**: Steam with Proton, Decky Loader, MangoHud, bunch of emulators
- **Music**: MPD with Euphonica client
- **Dev Tools**: Claude Code, Node/Python/Rust toolchains and LSPs

Everything's managed with Nix flakes and Hjem. I use ZFS because I like snapshots because I'd rather not lose stuff when I inevitably break something or delete something on accident. This just makes sense to pair with git and NixOS.

The files in `docs/` have more detailed instructions if you actually want to use this. Those files are primarally for me to reference for later.

## Adding stuff

Because of the flake-parts setup, adding new modules is ezpz. Everything in `modules/` gets auto-imported, just drop a file and it's in.

System-level stuff goes in `modules/nixos-modules/`:

```nix
{ inputs, self, ... }:
{
  flake.nixosModules.my-new-thing = { config, lib, pkgs, ... }:
    with lib; {
      config = mkIf config.mySystem.features.whatever {
        # your config here
      };
    };
}
```

User config files (anything that ends up in `~/.config` or `~/.local/share`) go in `modules/hjem/`:

```nix
{...}: {
  flake.nixosModules.my-app = { config, lib, pkgs, ... }: let
    username = config.mySystem.user.name;
  in with lib; {
    config = mkIf config.mySystem.features.whatever {
      hjem.users.${username}.xdg.config.files = {
        "my-app/config".text = ''
          # your config here
        '';
      };
    };
  };
}
```

Files prefixed with `_` are excluded from auto-import — that's how `_hardware-configuration.nix` stays out of the way.

## What you probably want to change

If you're actually going to use this:

1. **Hardware config**: Generate your own and drop it in `modules/hosts/_hardware-configuration.nix`
2. **User settings**: Change username, hostname in `modules/hosts/rig.nix`
3. **YubiKey stuff**: Disable it unless you have one (`yubikey = false`)
4. **GPU settings**: Change `amd = true` to whatever GPU you have
5. **ZFS pools**: Adjust pool names and datasets to match your setup
6. **Game storage**: The `zgames` pool is optional, remove it if you don't need it

## ZFS setup

- `zroot` pool on NVMe for system/nix/home
- `zgames` pool on a separate drive for games (optional)
- Automated hourly/daily/weekly/monthly snapshots via sanoid
- Compression and auto-trim enabled

## Docs

If you want more details:
- [Installation Guide](docs/INSTALLATION.md) - Full install instructions
- [Configuration Options](docs/CONFIGURATION.md) - All the knobs you can turn
- [Features](docs/FEATURES.md) - What's actually in here
- [Maintenance](docs/MAINTENANCE.md) - Routine maintenance and updates
- [Secrets](docs/SECRETS.md) - Agenix setup for managing secrets
- [Backups](docs/BACKUP.md) - ZFS snapshot management
- [Troubleshooting](docs/TROUBLESHOOTING.md) - When things break

## This is what I'm running:
- AMD CPU + AMD GPU
- 64GB RAM
- 1TB NVMe for system (zroot)
- 2TB SSD for games (zgames)
- YubiKey for hardware auth
- Bluetooth 5.0+

## Contributing

Feel free to fork this and do whatever. If you find bugs or have improvements, pull requests are welcome. But remember, this is primarily my personal config, and I am still fairly new to this stuff.

## License

MIT License. Do whatever you want with it.

## Links

- GitHub: https://github.com/weegs710/AnomalOS
- Codeberg: https://codeberg.org/weegs710/AnomalOS
