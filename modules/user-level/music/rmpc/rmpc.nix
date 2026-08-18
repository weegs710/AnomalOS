{
  config,
  pkgs,
  lib,
  ...
}:
let
  username = config.mySystem.user.name;
  homeDir = config.users.users.${username}.home;
  lyricsDir = "${homeDir}/.local/share/rmpc/lyrics";

  rmpcOpenScript = pkgs.writeTextFile {
    name = "rmpc-open";
    executable = true;
    destination = "/bin/rmpc-open";
    text = lib.replaceStrings [ "@NUSHELL@" ] [ "${pkgs.nushell}" ] (builtins.readFile ./rmpc-open.nu);
  };

  lyricsScript = pkgs.writeTextFile {
    name = "rmpc-lyrics";
    executable = true;
    destination = "/bin/rmpc-lyrics";
    text = lib.replaceStrings [ "@NUSHELL@" ] [ "${pkgs.nushell}" ] (
      builtins.readFile ./rmpc-lyrics.nu
    );
  };

in
{
  users.users.${username}.packages = [
    pkgs.rmpc
    pkgs.cava
    lyricsScript
    rmpcOpenScript
  ];

  hjem.users.${username} = {
    xdg.data.files."applications/rmpc-open.desktop".source = ./rmpc-open.desktop;

    xdg.config.files."rmpc/config.ron".text =
      lib.replaceStrings [ "@USER@" "@LYRICS_BIN@" ] [ username "${lyricsScript}/bin/rmpc-lyrics" ]
        (builtins.readFile ./config.ron);

    xdg.config.files."rmpc/themes/eldritch.ron".source = ./eldritch.ron;
  };

  systemd.user.tmpfiles.rules = [
    "d ${lyricsDir} 0755 - - -"
  ];

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".local/share/rmpc"
  ];
}
