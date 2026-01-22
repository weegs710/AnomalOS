# Desktop environment home-manager configuration
# Hyprland, Waybar, terminal, file manager, and other desktop applications
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hyprland
    ./noctalia
    ./nemo.nix
    ./ghostty.nix
    ./vesktop.nix
    ./xdg-apps.nix
    ./fastfetch.nix
    ./udiskie.nix
    ./mission-center.nix
    ./superfile.nix
    ./termfilechooser.nix
    ./helium.nix
  ];
}
