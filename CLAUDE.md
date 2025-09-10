# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a NixOS configuration repository using Nix flakes, managing both system-level configuration and user-level configuration via Home Manager. The configuration targets a desktop system (HX99G) running Hyprland as the window manager.

## Essential Commands

### System Management
- `nrs` - Rebuild and switch to new NixOS configuration (alias for `sudo nixos-rebuild switch --flake .#HX99G`)
- `nrt` - Test new NixOS configuration without switching (alias for `sudo nixos-rebuild test --flake .#HX99G`)
- `update-all` - Update flake inputs and rebuild system (`sudo nix flake update && nrs`)
- `update-all-test` - Update flake inputs and test rebuild (`sudo nix flake update && nrt`)
- `nfa` - Archive flake (alias for `nix flake archive`)
- `recycle` - Clean up old generations (alias for `sudo nix-collect-garbage --delete-older-than 7d`)

### Development Workflow
1. Make configuration changes in the dotfiles directory
2. Test changes: `nrt`
3. If working properly, apply permanently: `nrs`
4. For major updates: `update-all-test` then `update-all`

## Architecture

### Core Configuration Files
- `flake.nix` - Main flake definition with inputs and system configuration
- `configuration.nix` - System-level NixOS configuration
- `home.nix` - User-level Home Manager configuration
- `hardware-configuration.nix` - Hardware-specific settings

### Key Components

#### System Configuration (`configuration.nix`)
- **Hardware**: AMD GPU, Nvidia modesetting, Bluetooth, Steam hardware support
- **Security**: Polkit, PAM U2F authentication with YubiKey
- **Services**: Pipewire audio, Flatpak, SSH, display manager (SDDM), Hyprland
- **Networking**: NetworkManager, nftables firewall
- **Styling**: Stylix theming with Sugarplum color scheme

#### User Configuration (`home.nix`)
- **Window Manager**: Hyprland with custom keybindings and settings
- **Environment**: Kitty terminal, Zed editor, LibreWolf browser
- **Styling**: Master layout, custom animations, no window borders
- **Key Applications**: Rofi launcher, Thunar file manager, various media tools

#### Flake Structure
- Uses `nixpkgs` unstable channel
- Integrates `home-manager`, `stylix`, and `nix-flatpak`
- System name: HX99G

### User Environment
- **Shell**: Fish with Starship prompt
- **Editor**: Zed (`zeditor` command)
- **Terminal**: Kitty
- **Theme**: Sugarplum dark theme with custom colors
- **Font**: All Nerd Fonts are available

## Configuration Patterns

### Adding New Programs
1. For system programs: Add to `environment.systemPackages` in `configuration.nix`
2. For user programs: Add to `home.packages` in `home.nix`
3. For programs with NixOS modules: Enable in `programs.*` section

### Modifying Hyprland
- Keybindings are defined in `home.nix` under `wayland.windowManager.hyprland.settings.bind*`
- Window rules and workspace settings in the same section
- Startup applications in `exec-once`

### Adding Services
- System services: `services.*` in `configuration.nix`
- User services: Can be configured in `home.nix` under respective program configurations

### Shell Aliases
- Defined in `environment.shellAliases` in `configuration.nix`
- Current aliases include system management and application shortcuts

## Security Features
- YubiKey U2F authentication configured for login, sudo, SDDM, and polkit
- Firewall enabled with minimal open ports
- Trusted users configuration for Nix operations

## Styling and Theming
- Stylix manages consistent theming across applications
- Base16 Sugarplum color scheme with dark polarity
- Custom wallpaper: `monster.jpg`
- GTK and Qt theming enabled