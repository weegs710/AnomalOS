# Development tools home-manager configuration
# Code editors, shell configuration, and development utilities
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./fish.nix
    ./zed.nix
    # ./oh-my-posh.nix  # Disabled - uses stylix colors
  ];
}
