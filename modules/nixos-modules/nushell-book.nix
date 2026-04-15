{
  flake.nixosModules.nushell-book = {
    config,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    port = 8585;
    serveDir = "/home/${username}/Documents/nushell-book/.vuepress/dist";
  in {
    users.users.${username}.packages = [pkgs.miniserve];

    systemd.user.services.nushell-book = {
      description = "Nushell Book - local docs server";
      after = ["network.target"];
      wantedBy = ["default.target"];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.miniserve}/bin/miniserve --port ${toString port} --index index.html ${serveDir}";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
