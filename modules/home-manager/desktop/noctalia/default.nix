{
  config,
  lib,
  pkgs,
  osConfig,
  inputs,
  ...
}:
with lib; {
  imports = [inputs.noctalia.homeModules.default];

  config = mkIf osConfig.mySystem.features.desktop {
    programs.noctalia-shell = {
      enable = true;
      systemd.enable = false;
      settings = import ./settings.nix {inherit lib;};
    };

    home.packages = with pkgs; [
      qt6Packages.qt6ct
    ];

    home.sessionVariables = {
      NOCTALIA_SETTINGS_FALLBACK = "${config.xdg.configHome}/noctalia/gui-settings.json";
      QT_QPA_PLATFORMTHEME = "qt6ct";
    };
  };
}
