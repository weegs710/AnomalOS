{ config, lib, ... }:

let
  cfg = config.mySystem.features.desktop;  # Using existing desktop feature flag
in
{
  # Hyprland window manager feature
  # Multi-file structure: system.nix, config.nix, keybinds.nix, rules.nix, wallpaper.nix

  imports = [
    ./system.nix
    ./_config.nix
    ./_keybinds.nix
    ./_rules.nix
    ./_wallpaper.nix
  ];

  # All submodules are gated by mySystem.features.desktop
  # This provides a single enable point for the entire Hyprland stack
}
