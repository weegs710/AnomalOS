{
  config,
  lib,
  ...
}:
with lib; {
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
                {alert = {};}
                {http = {};}
                {dns = {};}
                {tls = {};}
                {ssh = {};}
                {stats = {};}
              ];
            };
          }
        ];
        default-rule-path = "/var/lib/suricata/rules";
        rule-files = ["suricata.rules"];
        app-layer.protocols.modbus.enabled = "no";
      };
    };

    services.logrotate.settings.suricata = {
      files = "/var/log/suricata/*.log /var/log/suricata/*.json";
      frequency = "daily";
      rotate = 7;
      compress = true;
      delaycompress = true;
      missingok = true;
      notifempty = true;
      create = "0640 root root";
      sharedscripts = true;
      postrotate = "systemctl reload suricata.service || true";
    };
  };
}
