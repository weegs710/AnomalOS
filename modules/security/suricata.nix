{ config, lib, ... }:

with lib;

{
  config = mkIf config.mySystem.features.security {
    services.suricata = {
      enable = true;
      settings = {
        af-packet = [
          {
            interface = "wlp6s0";
            cluster-id = 99;
            cluster-type = "cluster_flow";
            defrag = true;
          }
        ];
        outputs = [
          {
            fast = {
              enabled = true;
              filename = "/var/log/suricata/fast.log";
            };
          }
          {
            eve-log = {
              enabled = true;
              filetype = "regular";
              filename = "/var/log/suricata/eve.json";
              types = [
                { alert = { }; }
                { http = { }; }
                { dns = { }; }
                { tls = { }; }
                { ssh = { }; }
                { stats = { }; }
              ];
            };
          }
        ];
        default-rule-path = "/var/lib/suricata/rules";
        rule-files = [ "suricata.rules" ];
        app-layer.protocols.modbus.enabled = "no";
      };
    };
  };
}
