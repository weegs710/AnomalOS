{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.desktop {
    # Stylix theming
    stylix = {
      enable = true;
      enableReleaseChecks = false;
      # base16Scheme = ./anomal-16.yaml;
      # base16Scheme = "${pkgs.base16-schemes}/share/themes/outrun-dark.yaml";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/isotope.yaml";
      # base16Scheme = ./oxocarbon-dark.yaml;
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
