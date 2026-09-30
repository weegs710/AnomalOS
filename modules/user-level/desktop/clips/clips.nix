{
  config,
  lib,
  pkgs,
  ...
}:
let
  # the encode gets its own unit so a gsr restart can't kill it midway
  onSave = pkgs.writeShellScript "clip-on-save" ''
    exec ${config.systemd.package}/bin/systemd-run --user --collect --quiet \
      -E PATH=${
        lib.makeBinPath [
          pkgs.ffmpeg
          pkgs.libnotify
        ]
      } \
      ${lib.getExe pkgs.nushell} ${./clip-encode.nu} "$@"
  '';
in
{
  # saves are triggered by the Mod+F binds in umbriel's config.toml
  systemd.user.services.gsr-replay = {
    description = "gpu-screen-recorder replay buffer";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      # every save is re-encoded to av1, which can't recover detail the buffer never kept
      ExecStart = lib.concatStringsSep " " [
        (lib.getExe pkgs.gpu-screen-recorder)
        "-v no -w screen -s 1920x1080 -f 60 -k h264 -bm cbr -q 12000"
        "-a default_output -ac aac -c mp4 -r 1800"
        "-o %h/Videos/clips -ro %h/Videos/clips"
        "-ipc %t/gsr.sock -sc ${onSave}"
      ];
      KillSignal = "SIGINT";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
