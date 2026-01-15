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

    xdg.configFile."vesktop/settings/settings.json" = {
      force = true;
      text = builtins.toJSON {
        enabledThemes = ["noctalia.theme.css"];
        autoUpdate = true;
        useQuickCss = true;
      };
    };
  };
}
