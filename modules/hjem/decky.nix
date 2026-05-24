{
  config,
  pkgs,
  inputs,
  ...
}:
let
  username = config.mySystem.user.name;
  wrappedSteam = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.steam;
in
{
  # Create directories for decky
  systemd.tmpfiles.rules = [
    "d /home/${username}/homebrew 0755 ${username} users -"
    "d /home/${username}/homebrew/services 0755 ${username} users -"
    "d /home/${username}/homebrew/plugins 0755 ${username} users -"
  ];

  # Setup service that creates CEF debug files, symlinks the binary
  systemd.user.services.decky-loader-setup = {
    description = "Decky Loader Setup";
    before = [ "decky-loader.service" ];
    wantedBy = [ "default.target" ];

    script = ''
      # Create CEF remote debugging files
      mkdir -p $HOME/.steam/steam
      touch $HOME/.steam/steam/.cef-enable-remote-debugging
      mkdir -p $HOME/.var/app/com.valvesoftware.Steam/data/Steam
      touch $HOME/.var/app/com.valvesoftware.Steam/data/Steam/.cef-enable-remote-debugging

      # Symlink decky loader binary
      ln -sf ${wrappedSteam.passthru.decky-loader}/bin/PluginLoader $HOME/homebrew/services/PluginLoader
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  systemd.user.services.decky-loader = {
    description = "Decky Loader - Steam Deck plugin system";
    after = [
      "graphical-session.target"
      "decky-loader-setup.service"
    ];
    partOf = [ "graphical-session.target" ];
    requires = [ "decky-loader-setup.service" ];
    wantedBy = [ "default.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "/home/${username}/homebrew/services/PluginLoader";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    path = [
      pkgs.python3
      pkgs.systemd
      pkgs.coreutils
      pkgs.curl
      pkgs.git
    ];

    environment = {
      PLUGIN_PATH = "/home/${username}/homebrew/plugins";
      LOG_LEVEL = "INFO";
    };
  };

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/decky-loader"
  ];
}
