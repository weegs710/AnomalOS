{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.desktop {
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
}
