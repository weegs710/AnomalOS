{...}: {
  flake.nixosModules.udiskie = {
    config,
    lib,
    ...
  }:
    with lib; {
      config = mkIf config.mySystem.features.desktop {
        home-manager.users.${config.mySystem.user.name} = {
          services.udiskie = {
            enable = true;
            automount = true;
            notify = true;
            tray = "auto";
          };
        };
      };
    };
}
