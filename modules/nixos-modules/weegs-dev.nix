{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
  port = 1111;
  serveDir = "/home/${username}/weegs.dev";
in
{
  users.users.${username}.packages = [ pkgs.miniserve ];

  systemd.user.services.weegs-dev = {
    description = "weegs.dev - local dev server";
    after = [ "network.target" ];
    wantedBy = [ "default.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.miniserve}/bin/miniserve --port ${toString port} --index index.html ${serveDir}";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
