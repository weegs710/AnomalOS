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
      base16Scheme = ./axion.yaml;
      polarity = "dark";

      # Font configuration
      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.terminess-ttf;
          name = "Terminess Nerd Font";
        };
        sansSerif = {
          package = pkgs.google-fonts.override {
            fonts = ["Orbitron"];
          };
          name = "Orbitron";
        };
        serif = {
          package = pkgs.google-fonts.override {
            fonts = ["SpaceGrotesk"];
          };
          name = "Space Grotesk";
        };
        sizes = {
          applications = 12;
          terminal = 13;
          desktop = 10;
          popups = 12;
        };
      };

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
