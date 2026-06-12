{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
in
{
  users.users.${username}.packages = [ pkgs.mpv ];

  hjem.users.${username}.xdg.config.files."mpv/mpv.conf".source = ./mpv.conf;

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/mpv"
    ".local/state/mpv"
  ];
}
