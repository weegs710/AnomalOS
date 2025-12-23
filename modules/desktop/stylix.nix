{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.desktop {
    # Stylix theming
    stylix = {
      enable = true;
      enableReleaseChecks = false;
      base16Scheme = ./axion.yaml;
      polarity = "dark";
      targets = {
        gtk.enable = true;
        qt.enable = true;
        console.enable = true;
        grub.enable = true;
        plymouth.enable = true;
        nixos-icons.enable = true;
      };
    };
  };
}
