{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; {
  imports = [
    ./config.nix
    ./style.nix
  ];

  config = mkIf osConfig.mySystem.features.desktop {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
    };
  };
}
