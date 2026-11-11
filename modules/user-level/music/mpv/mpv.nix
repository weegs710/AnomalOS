{
  config,
  lib,
  pkgs,
  only,
  ...
}:
let
  username = config.mySystem.user.name;
in
only.gate { tags = [ "desktop" ]; } {
  users.users.${username}.packages = [ pkgs.mpv ];

  hjem.users.${username}.xdg.config.files."mpv/mpv.conf".text =
    lib.replaceStrings [ "@REFRESH@" ] [ (toString config.mySystem.display.refresh) ]
      (builtins.readFile ./mpv.conf);

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/mpv"
    ".local/state/mpv"
  ];
}
