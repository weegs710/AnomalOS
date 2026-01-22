# Core home-manager configuration
# Base packages, XDG settings, and essential user config
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./packages.nix
    ./xdg.nix
  ];
}
