{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.development {
  };
}
