{...}: {
  flake.nixosModules.hyprland-wallpaper = {
    config,
    lib,
    ...
  }:
    with lib; {
      config = mkIf config.mySystem.features.desktop {
        home-manager.users.${config.mySystem.user.name} = {
          services.swww = {
            enable = true;
          };

          systemd.user.services.swww = {
            Unit = {
              After = lib.mkForce [];
              PartOf = ["graphical-session.target"];
            };
          };
        };
      };
    };
}
