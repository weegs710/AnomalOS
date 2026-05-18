{ config, ... }:
let
  username = config.mySystem.user.name;
in
{
  hjem.users.${username}.xdg.config.files."kdeconnect/config".text = ''
    [General]
    customDevices=['100.121.71.20']
    keyAlgorithm=EC
    name=${config.networking.hostName}
  '';

  environment.persistence."/persist".users.${username}.directories = [
    ".config/kdeconnect"
  ];
}
