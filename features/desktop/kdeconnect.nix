{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.kdeconnect {
    programs.kdeconnect.enable = true;

    # Ports 1714-1764 required for device discovery and file transfers
    networking.firewall = rec {
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = allowedTCPPortRanges;
    };

    environment.systemPackages = with pkgs; [
      kdePackages.kdeconnect-kde
    ];

    home-manager.users.${config.mySystem.user.name} = {
      services.kdeconnect.enable = true;
    };
  };
}
