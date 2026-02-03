{...}: {
  flake.nixosModules.kdeconnect = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; {
      config = mkIf config.mySystem.features.kdeconnect {
        programs.kdeconnect.enable = true;
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

        systemd.user.services.kdeconnect = {
          description = "KDE Connect";
          after = ["graphical-session.target"];
          wantedBy = ["graphical-session.target"];

          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnectd";
            Restart = "on-failure";
          };
        };
      };
    };
}
