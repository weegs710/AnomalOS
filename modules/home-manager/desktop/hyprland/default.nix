{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: {
  imports = [
    ./wallpaper.nix
    ./config.nix
    ./keybinds.nix
    ./rules.nix
  ];
}
