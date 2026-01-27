{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; {
  # Noctalia shell UI feature - includes gui-settings.json for reproducibility

  config = mkIf config.mySystem.features.desktop {
    home-manager.users.${config.mySystem.user.name} = {
      imports = [inputs.noctalia.homeModules.default];

      programs.noctalia-shell = {
        enable = true;
        systemd.enable = false;
        settings = import ./_settings.nix {inherit lib;};
      };

      home.packages = with pkgs; [
        qt6Packages.qt6ct
      ];

      home.sessionVariables = {
        NOCTALIA_SETTINGS_FALLBACK = "${config.home-manager.users.${config.mySystem.user.name}.xdg.configHome}/noctalia/gui-settings.json";
        QT_QPA_PLATFORMTHEME = "qt6ct";
      };

      # Deploy gui-settings.json for reproducible Noctalia config
      xdg.configFile."noctalia/gui-settings.json".source = ./gui-settings.json;
    };
  };
}
