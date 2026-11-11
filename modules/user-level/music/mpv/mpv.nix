{
  config,
  lib,
  pkgs,
  only,
  ...
}:
let
  username = config.mySystem.user.name;
  # lua 5.2 is EOL with CVE-2021-43519 unfixed; luajit serves the same lua_compat interface
  mpv = pkgs.mpv.override {
    mpv-unwrapped = pkgs.mpv-unwrapped.override { lua5_2_compat = pkgs.luajit; };
  };
in
only.gate { tags = [ "desktop" ]; } {
  users.users.${username}.packages = [ mpv ];

  hjem.users.${username}.xdg.config.files."mpv/mpv.conf".text =
    lib.replaceStrings [ "@REFRESH@" ] [ (toString config.mySystem.display.refresh) ]
      (builtins.readFile ./mpv.conf);

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/mpv"
    ".local/state/mpv"
  ];
}
