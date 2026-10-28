{
  config,
  lib,
  pkgs,
  ...
}:
{
  # saves are triggered by the Mod+F binds in umbriel's config.toml
  hjem.users.${config.mySystem.user.name}.systemd.services.gsr-replay = {
    description = "gpu-screen-recorder replay buffer";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = lib.concatStringsSep " " [
        (lib.getExe pkgs.gpu-screen-recorder)
        "-v no -w screen -s 1920x1080 -f 60 -k h264 -bm cbr -q 12000"
        "-a default_output -ac aac -c mp4 -r 1800"
        "-o %h/Videos/clips -ro %h/Videos/clips"
        "-ipc %t/gsr.sock"
      ];
      KillSignal = "SIGINT";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
