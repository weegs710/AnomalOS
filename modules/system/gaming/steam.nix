{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.gaming {
    programs.steam = {
      enable = true;
      protontricks.enable = true;
      gamescopeSession.enable = true;
      extest.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      extraPackages = with pkgs; [
        mangohud
      ];
    };

    environment.sessionVariables = {
      SDL_VIDEODRIVER = "wayland";
    };
  };
}
