{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.security {
    networking.firewall = {
      # Allow SSH on non-standard port + gaming ports if gaming enabled
      allowedTCPPorts = [2222] ++ (optionals config.mySystem.features.gaming ([8080 1337] ++ (lib.range 23243 23262)));
      allowedUDPPorts = optionals config.mySystem.features.gaming [
        23253
        23243
      ];
    };
  };
}
