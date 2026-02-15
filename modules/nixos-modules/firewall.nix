{
  flake.nixosModules.firewall = {
    config,
    lib,
    ...
  }: {
    config = lib.mkIf config.mySystem.features.security {
        networking.firewall = {
          allowedTCPPorts = [2222] ++ (lib.optionals config.mySystem.features.gaming ([8080 1337] ++ (lib.range 23243 23262)));
          allowedUDPPorts = lib.optionals config.mySystem.features.gaming [
            23253
            23243
          ];
        };
      };
    };
}
