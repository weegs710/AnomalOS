{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.desktop {
    # Mission Center - Modern GUI system monitor with GPU support
    home.packages = with pkgs; [
      mission-center
    ];
  };
}
