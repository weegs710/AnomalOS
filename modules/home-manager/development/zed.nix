{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.development {
    programs.zed-editor = {
      enable = true;
      extensions = ["nix"];
      userSettings = {
        theme = "Noctalia Dark";
      };
    };
  };
}
