{
  config,
  pkgs,
  weegsware,
  ...
}:
let
  username = config.mySystem.user.name;
  homebrew = "/home/${username}/homebrew";
  decky-loader = weegsware.steam.passthru.decky-loader;
in
{
  # decky self-creates these on first run; pre-make them user-owned so they aren't created root-owned
  systemd.tmpfiles.rules = [
    "d ${homebrew} 0755 ${username} users -"
    "d ${homebrew}/plugins 0755 ${username} users -"
  ];

  # Steam reads this at launch to expose its CEF debugger on :8080, which decky and every plugin hook into
  systemd.user.tmpfiles.rules = [
    "f %h/.local/share/Steam/.cef-enable-remote-debugging 0644 - - -"
  ];

  systemd.user.services.decky-loader = {
    description = "Decky Loader - Steam Deck plugin system";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "default.target" ];

    # plugins shell out to these at runtime
    path = [
      pkgs.python3
      pkgs.systemd
      pkgs.coreutils
      pkgs.curl
      pkgs.git
    ];

    # point decky at the preserved ~/homebrew tree instead of its /home/deck default
    environment = {
      UNPRIVILEGED_PATH = homebrew;
      UNPRIVILEGED_USER = username;
      PLUGIN_PATH = "${homebrew}/plugins";
      LOG_LEVEL = "INFO";
    };

    serviceConfig = {
      Type = "simple";
      ExecStart = "${decky-loader}/bin/decky-loader";
      WorkingDirectory = homebrew;
      Restart = "always";
      RestartSec = "5s";
    };
  };
}
