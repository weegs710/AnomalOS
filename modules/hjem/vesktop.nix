{...}: {
  flake.nixosModules.vesktop = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; let
      username = config.mySystem.user.name;
    in {
      config = mkIf config.mySystem.features.desktop {
        users.users.${username}.packages = [pkgs.vesktop];

        hjem.users.${username} = {
          xdg.config.files."vesktop/settings/settings.json".text = builtins.toJSON {
            enabledThemes = ["noctalia.theme.css"];
            autoUpdate = true;
            useQuickCss = true;
          };
        };
      };
    };
}
