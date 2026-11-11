{
  config,
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

    preservation.preserveAt."/persist".users.${username}.directories = [ ".config/jj" ];

    hjem.users.${username} = {
      xdg.config.files."git/config".source = ./git-config;
      xdg.config.files."jj/config.toml".source = ./jj-config.toml;
    };
  };
}
