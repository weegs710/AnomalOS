{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  config = mkIf config.mySystem.features.desktop {
    # Stylix theming
    stylix = {
      enable = true;
      base16Scheme = ./anomal-16.yaml;
      image = ./AnomalOS.webp;
      polarity = "dark";
      imageScalingMode = "stretch";
      targets = {
        gtk.enable = true;
        qt.enable = true;
        console.enable = true; # TTY theming
        grub.enable = true; # Bootloader theme
        plymouth.enable = true; # Boot splash
        nixos-icons.enable = true; # System icons
      };
    };
  };
}
