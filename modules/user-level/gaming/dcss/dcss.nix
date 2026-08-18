{
  config,
  pkgs,
  lib,
  ...
}:
let
  username = config.mySystem.user.name;
in
{
  users.users.${username}.packages = [ pkgs.crawlTiles ];

  hjem.users.${username}.files.".crawl/init.txt".text = lib.replaceStrings [ "@USER@" ] [ username ] (
    builtins.readFile ./init.txt
  );
}
