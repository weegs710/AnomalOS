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
      base16Scheme = {
        base00 = "1b002b";
        base01 = "1c0c25";
        base02 = "261033";
        base03 = "2f143f";
        base04 = "16081f";
        base05 = "b392f0";
        base06 = "c7aaff";
        base07 = "ffffff";
        base08 = "ff6666";
        base09 = "ffaa55";
        base0A = "ffff66";
        base0B = "aaffaa";
        base0C = "66ccff";
        base0D = "9999ff";
        base0E = "cc66cc";
        base0F = "a565f0";
        scheme = "Purple Colony";
        author = "weegs710";
      };
      image = ./AnomalOS.png;
      polarity = "dark";
      imageScalingMode = "stretch";
      targets = {
        gtk.enable = true;
        qt.enable = true;
      };
    };
  };
}
