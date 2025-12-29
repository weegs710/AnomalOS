{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.desktop {
    programs.vesktop.enable = true;
    stylix.targets.vesktop.enable = true;
  };
}
