{
  config,
  lib,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
in
{
  config = {
    users.users.${username}.packages = [ pkgs.git ];

    hjem.users.${username} = {
      xdg.config.files."git/config".text = ''
        [user]
          name = weegs710
          email = weegs@tutamail.com
      '';
    };
  };
}
