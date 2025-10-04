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
      base16Scheme = {
        base00 = "111147";
        base01 = "1a1a5c";
        base02 = "565f89";
        base03 = "6b7394";
        base04 = "a8b5d1";
        base05 = "d0beee";
        base06 = "dbc8f0";
        base07 = "e6d4f5";
        base08 = "b53dff";
        base09 = "2082a6";
        base0A = "7dcfff";
        base0B = "53b397";
        base0C = "249a84";
        base0D = "5ca8dc";
        base0E = "a175d4";
        base0F = "db7ddd";
        scheme = "Sugarplum";
        author = "lemonlime0x3C33 (converted)";
      };
      image = ./monster.jpg;
      polarity = "dark";
      targets = {
        gtk.enable = true;
        qt.enable = true;
      };
    };
  };
}
