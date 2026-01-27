{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.security {
    services.suricata = {
      enable = true;
      disabledRules = [
        # WiFi packet loss triggers millions of TCP state machine alerts
        "2210020"
        "2210029"
        "2210044"
        "2210045"
        "2210054"

        # Protocol decode errors - normal on heterogeneous networks
        "2200000"
        "2200121"
        "2230002"
        "2230009"
        "2230015"
        "2260001"
        "2260002"

        # JA3 fingerprints match legitimate TLS libraries, not just malware
        "906200068"
        "906200070"

        # Steam uses non-standard port 27020 for CM servers
        "3300298"
        "2028651"

        # Discord is legitimate
        "2035464"
        "2060504"
        "2060505"
        "2035463"
        "3300790"

        # dnscrypt-proxy uses Cloudflare DoH; mDNS is normal LAN discovery
        "2027695"
        "3300149"
        "3300150"
        "3300153"
        "3300154"

        # Development tools in regular use
        "3321272"
        "3321271"
        "3300195"
        "3321417"

        # Video calling infrastructure
        "2033078"
        "3300159"

        # TLD and CDN observations provide no actionable security value
        "2031231"
        "3301064"
        "3301069"
        "3301057"
        "3301058"
        "3301062"
        "3301072"
        "3301075"
        "2052581"
        "2051768"
        "2057746"
        "3300032"
        "3300800"
        "3300801"
        "3300347"
        "3321365"

        # Legacy TLS versions are informational, not blockable threats
        "3300244"
        "3300245"
        "3300246"
      ];

      settings = {
        logging = {
          default-log-level = "notice";
          outputs.console = {
            enabled = lib.mkForce "true";
          };
        };

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
              append = "no";
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
        # Industrial protocols irrelevant to home networks
        app-layer.protocols.modbus.enabled = "no";
        app-layer.protocols.dnp3.enabled = "no";
      };
    };

    # Fix NixOS module bug: ProtectProc=true is invalid
    systemd.services.suricata.serviceConfig.ProtectProc = lib.mkForce "invisible";

    services.logrotate.settings.suricata = {
      files = "/var/log/suricata/*.log /var/log/suricata/*.json";
      frequency = "daily";
      rotate = 3;
      compress = true;
      delaycompress = false;
      missingok = true;
      notifempty = true;
      create = "0640 suricata suricata";
      sharedscripts = true;
      size = "1G";
      postrotate = "systemctl kill -s HUP suricata.service || true";
    };
  };
}
