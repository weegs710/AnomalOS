# My NixOS Setup - anomalOS

> **Important**: This config is designed for my machine and my workflow. It might work on your system, it might not. There are no guarantees. You're welcome to use the whole thing or just steal bits and pieces. It's all FOSS, so do whatever you want with it.

## What's in here

I run Hyprland on NixOS with a bunch of stuff I've cobbled together over time:

- **Desktop**: Hyprland compositor with Noctalia shell UI
- **Login**: Ly display manager (works with my YubiKey for login)
- **Shell**: Fish with Oh My Posh prompt
- **Editor**: Zed
- **Terminal**: Ghostty
- **Filesystem**: ZFS with automated snapshots
- **Security**: YubiKey for authentication, Suricata IDS, hardened firewall
- **Gaming**: Steam with Proton, Decky Loader, MangoHud, bunch of emulators
- **Music**: MPD with Euphonica client, Beets for library management
- **Dev Tools**: Claude Code, Node/Python/Rust toolchains, language servers

Everything's managed with Nix flakes and home-manager. I use ZFS because I like snapshots because I'd rather not lose stuff when I inevitably break something or delete something on accident. This just makes sense to pair with git and NixOS.

## How it's organized

```
dotfiles/
├── flake.nix                    # Main flake
├── modules/
│   ├── hosts/rig.nix            # My system config
│   └── nixos-modules/           # All the feature modules (55 of them)
└── docs/                        # Docs if you want more details
```

**Fair warning**: This is set up for my AMD GPU, my YubiKey, my dual-drive ZFS setup. You'll probably need to change a bunch of stuff.

```bash
# Clone it
git clone https://github.com/weegs710/AnomalOS.git ~/dotfiles
cd ~/dotfiles

# Generate hardware config for your machine
sudo nixos-generate-config --show-hardware-config > hardware-configuration-zfs.nix

# Test it first (seriously, don't skip this)
sudo nixos-rebuild test --flake .#nixosConfigurations.Rig

# If that worked, apply it
sudo nixos-rebuild switch --flake .#nixosConfigurations.Rig
sudo reboot
```

The docs in `docs/` have more detailed instructions if you actually want to use this. Those files are primarally for me to reference for later.

## Managing updates

After the initial install, I use these aliases:

```bash
nrt-rig    # Test changes
nrs-rig    # Apply changes
rig-up     # Update everything and prompt to switch
```

## Customization

Everything's controlled from `modules/hosts/rig.nix`. You can turn features on/off there:

```nix
mySystem.features = {
  desktop = true;
  gaming = true;
  yubikey = true;      # You probably don't have a YubiKey
  claudeCode = true;   # Claude Code integration
  # ... etc
};

mySystem.hardware = {
  amd = true;          # Set to false if you have Intel/NVIDIA
  bluetooth = true;
  steam = true;
};
```

## Adding stuff

Because of the flake-parts setup, adding new modules ezpz. Just create a file in `modules/nixos-modules/`:

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

## What you probably want to change

If you're actually going to use this:

1. **Hardware config**: Generate your own `hardware-configuration-zfs.nix`
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

Check `docs/BACKUP.md` for snapshot management details.

## Docs

If you want more details:
- [Installation Guide](docs/INSTALLATION.md) - Full install instructions
- [Configuration Options](docs/CONFIGURATION.md) - All the knobs you can turn
- [Features](docs/FEATURES.md) - What's actually in here
- [Customization](docs/CUSTOMIZATION.md) - How to make it yours
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

---

This is a hobbyist project. I'm learning as I go. If something's broken or stupid, that's why.
