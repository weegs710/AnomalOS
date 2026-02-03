{...}: {
  flake.nixosModules.noctalia = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; let
      username = config.mySystem.user.name;
    in {
      config = mkIf config.mySystem.features.desktop {
        users.users.${username}.packages = with pkgs; [
          noctalia-shell
          qt6Packages.qt6ct
        ];

        environment.sessionVariables = {
          QT_QPA_PLATFORMTHEME = "qt6ct";
        };

        hjem.users.${username} = {
          xdg.config.files."noctalia/settings.json" = {
            source = ./settings.json;
            type = "copy";
            permissions = "0644";
          };
        };
      };
    };
}
