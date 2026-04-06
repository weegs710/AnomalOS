{
  flake.nixosModules.kdeconnect = {
    config,
    lib,
    ...
  }: let
    username = config.mySystem.user.name;
  in {
    config = lib.mkIf config.mySystem.features.desktop {
      hjem.users.${username}.xdg.config.files."kdeconnect/config".text = ''
        [General]
        customDevices=['100.121.71.20']
        keyAlgorithm=EC
        name=${config.networking.hostName}
      '';
    };
  };
}
