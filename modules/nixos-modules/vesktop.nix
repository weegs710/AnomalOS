{...}: {
  flake.nixosModules.vesktop = {
    config,
    lib,
    ...
  }:
    with lib; {
      config = mkIf config.mySystem.features.desktop {
        home-manager.users.${config.mySystem.user.name} = {
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
      };
    };
}
