{
  flake.nixosModules.udiskie = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
  in {
    config = lib.mkIf config.mySystem.features.desktop {
      users.users.${username}.packages = [pkgs.udiskie];

      systemd.user.targets.tray = {
        description = "System Tray";
        wantedBy = ["graphical-session.target"];
      };

      systemd.user.services.udiskie = {
        description = "udiskie - automount removable media";
        after = ["graphical-session.target"];
        partOf = ["graphical-session.target"];
        wantedBy = ["graphical-session.target"];

        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.udiskie}/bin/udiskie --tray";
          Restart = "on-failure";
        };
      };
    };
  };
}
