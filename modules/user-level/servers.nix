{
  config,
  pkgs,
  only,
  ...
}:
let
  username = config.mySystem.user.name;
in
only.gate { tags = [ "dev" ]; } {
  users.users.${username}.packages = [ pkgs.miniserve ];

  # per-user units: a global systemd.user.services also runs in the greeter's manager, where /home/${username} is unreadable
  hjem.users.${username}.systemd.services = {
    weegs-dev = {
      description = "weegs.dev - local dev server";
      after = [ "network.target" ];
      wantedBy = [ "default.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.miniserve}/bin/miniserve -i 127.0.0.1 --port 1111 --index index.html /home/${username}/repo/private/weegs.dev";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
