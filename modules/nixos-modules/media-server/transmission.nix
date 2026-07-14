{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;

  transmissionAdd = pkgs.makeDesktopItem {
    name = "transmission-add";
    desktopName = "Add to Transmission";
    exec = "${pkgs.transmission_4}/bin/transmission-remote --add %u";
    mimeTypes = [
      "application/x-bittorrent"
      "x-scheme-handler/magnet"
    ];
    noDisplay = true;
  };
in
{
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    group = "media";
    openRPCPort = false;
    openPeerPorts = true;
    settings = {
      download-dir = "/mnt/media/torrents";
      rpc-bind-address = "127.0.0.1";
      rpc-whitelist = "127.0.0.1";
      rpc-whitelist-enabled = true;
      rpc-host-whitelist-enabled = true;
      rpc-host-whitelist = "localhost,127.0.0.1";
      encryption = 1;
      utp-enabled = true;
      ratio-limit = 0;
      ratio-limit-enabled = true;
      umask = 2;
      download-queue-size = 9999;
      download-queue-enabled = true;
    };
  };

  preservation.preserveAt."/persist".directories = [ "/var/lib/transmission" ];

  users.users.${username}.packages = [ transmissionAdd ];

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/transmission"
  ];
}
