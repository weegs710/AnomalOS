# My NixOS Setup - anomalOS

> **Important**: This is a hobbyist project. I'm learning as I go. If something's broken or stupid, that's why. This config is designed for my machine and my workflow. It might work on your system, it might not. There are no guarantees. You're welcome to use the whole thing or just steal bits and pieces. It's all FOSS, so do whatever you want with it.

## What's in here

- **Custom Kernel:** CachyOS Linux 6.19.2 with x86-64-v3 optimizations (PGO/AutoFDO/LTO), BBR3 congestion control, hardened security sysctls, and ZFS support.
- **Window Manager**: Hyprland compositor with Noctalia shell UI
- **Display Manager**: Ly
- **Shell**: Fish with Oh My Posh prompt
- **Editor**: Flow Control
- **Terminal**: Ghostty
- **Filesystem**: ZFS with automated snapshots
- **Gaming**: Steam with Proton, Decky Loader, MangoHud, bunch of emulators

## My ZFS setup

- `zroot` pool on NVMe for system/nix/home
- `zgames` pool on a separate drive for games (optional)
- Automated hourly/daily/weekly/monthly snapshots via sanoid
- Compression and auto-trim enabled

The files in `docs/` have more detailed instructions if you actually want to use this. Those files are primarally for me to reference for later.


## Adding stuff

Everything is managed with flake parts and hjem. I also include fully portable preconfigured pkgs in shareables. I use ZFS because I like the compression and snapshot saftey net, I'd rather not lose stuff when I inevitably break or delete something on accident. This just makes sense to pair with jujutsu and NixOS. I am also using tmpfs for impermanence with a small size as a tripwire to remind me when I forgot to persist something.
Because of the flake-parts setup, adding new modules is ezpz. Everything in `modules/` gets auto-imported, just drop a file and it's in.
Files prefixed with `_` are excluded from auto-import with file filtering — that's how `_hardware-configuration.nix` stays out of the way.

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

## Docs

If you want more details:
- [Installation Guide](docs/INSTALLATION.md) - Full install instructions
- [Configuration Options](docs/CONFIGURATION.md) - All the knobs you can turn
- [Features](docs/FEATURES.md) - What's actually in here
- [Maintenance](docs/MAINTENANCE.md) - Routine maintenance and updates
- [Secrets](docs/SECRETS.md) - Agenix setup for managing secrets
- [Backups](docs/BACKUP.md) - ZFS snapshot management
- [Troubleshooting](docs/TROUBLESHOOTING.md) - When things break

## Contributing

Feel free to fork this and do whatever. If you find bugs or have improvements, pull requests are welcome -- I would prefer that you utilize the devshell to ensure that you use the same tooling and formatter I do. But remember, this is primarily my personal config, and I am still fairly new to this stuff.

## License

MIT License. Do whatever you want with it.

## Links

- GitHub: https://github.com/weegs710/AnomalOS
- Codeberg: https://codeberg.org/weegs710/AnomalOS
