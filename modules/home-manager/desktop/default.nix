# Desktop environment home-manager configuration
# Hyprland, Waybar, terminal, file manager, and other desktop applications
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hyprland
    # ./waybar  # Replaced by noctalia shell
    ./noctalia
    ./nemo.nix
    ./ghostty.nix
    ./swaync.nix
    ./vesktop.nix
    ./xdg-apps.nix
    ./fastfetch.nix
    ./udiskie.nix
    ./mission-center.nix
  ];
}
