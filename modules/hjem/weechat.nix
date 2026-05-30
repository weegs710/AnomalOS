{ config, pkgs, ... }:
let
  username = config.mySystem.user.name;
in
{
  users.users.${username}.packages = [ pkgs.weechat ];

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/weechat"
  ];
}
