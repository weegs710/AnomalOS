{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: {
  imports = [
    ./wallpaper.nix
    ./hyprlock.nix
    ./config.nix
    ./keybinds.nix
    ./rules.nix
  ];
}
