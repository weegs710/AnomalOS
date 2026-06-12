{ config, ... }:
let
  username = config.mySystem.user.name;
in
{
  hjem.users.${username} = {
    xdg.config.files."MangoHud/MangoHud.conf".source = ./MangoHud.conf;
    xdg.config.files."MangoHud/presets.conf".source = ./presets.conf;
  };
}
