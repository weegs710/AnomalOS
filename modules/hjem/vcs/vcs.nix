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
    users.users.${username}.packages = [
      pkgs.git
      pkgs.jujutsu
    ];

    hjem.users.${username} = {
      xdg.config.files."git/config".source = ./git-config;
      xdg.config.files."jj/config.toml".source = ./jj-config.toml;
    };
  };
}
