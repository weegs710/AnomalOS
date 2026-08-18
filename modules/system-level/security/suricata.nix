{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = {
    services.suricata = {
      enable = true;
      disabledRules = [
        "2210020"
        "2210029"
        "2210044"
        "2210045"
        "2210054"
        "2200000"
        "2200121"
        "2230002"
        "2230009"
        "2230015"
        "2260001"
        "2260002"
        "906200068"
        "906200070"
        "3300298"
        "2028651"
        "2035464"
        "2060504"
        "2060505"
        "2035463"
        "3300790"
        "2027695"
        "3300149"
        "3300150"
        "3300153"
        "3300154"
        "3321272"
        "3321271"
        "3300195"
        "3321417"
        "2033078"
        "3300159"
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
        "3300244"
        "3300245"
        "3300246"
        # Go HTTP client -- fires thousands of times daily on legitimate Go tools (tailscale, etc.)
        "3300111"
        "2024897"
        "2060251"
      ];

      settings = {
        logging = {
          default-log-level = "notice";
          outputs.console = {
            enabled = lib.mkForce "true";
          };
        };

        # required by nixos module assertion; actual packet processing uses nfq mode below, not af-packet
        af-packet = [
          {
            interface = "enp5s0";
            cluster-id = 99;
            cluster-type = "cluster_flow";
            defrag = true;
          }
        ];

        nfq = {
          mode = "accept";
          # if suricata dies or queue fills, pass traffic rather than dropping everything
          "fail-open" = true;
        };

        stream = {
          inline = "auto";
        };

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
        app-layer.protocols.dnp3.enabled = "no";
      };
    };

    systemd.services.suricata = {
      after = lib.mkForce [
        "basic.target"
        "network.target"
        "nftables.service"
      ];
      wants = lib.mkForce [ ];
      # multi-user.target infers After= from .wants/ symlinks; removing entry is the only way to unblock
      wantedBy = lib.mkForce [ ];
      serviceConfig = {
        ProtectProc = lib.mkForce "invisible";
        # nixos module hardcodes -i <iface>; no native NFQ option exists so override is required
        ExecStart = lib.mkForce "!${config.services.suricata.package}/bin/suricata -c ${config.services.suricata.configFile} -q 0";
      };
    };

    # nftables sets up the NFQ queue suricata listens on; logical coupling, starts suricata in background
    systemd.services.nftables.wants = [ "suricata.service" ];

    systemd.services.suricata-update = {
      # removed from boot; timer handles periodic updates instead
      wantedBy = lib.mkForce [ ];
      serviceConfig.ExecStartPost =
        # -: ignore failure if suricata isn't running; +: elevated to signal another service
        "-+${pkgs.systemd}/bin/systemctl kill --signal=USR2 suricata.service";
    };

    systemd.timers.suricata-update = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "24h";
      };
    };

    networking.nftables.tables.suricata-ips = {
      family = "inet";
      content = ''
        chain input {
          type filter hook input priority -5;
          iif lo accept
          iifname "tailscale0" accept
          iifname "virbr0" accept
          queue num 0 bypass
        }
        chain output {
          type filter hook output priority -5;
          oif lo accept
          oifname "tailscale0" accept
          queue num 0 bypass
        }
      '';
    };

    # nix build sandbox lacks nfqueue -- swap queue rules for accept during ruleset validation only
    networking.nftables.preCheckRuleset = ''
      sed -i 's/queue num 0 bypass/accept/g' ruleset.conf
    '';

    # the upstream d rule only chowns the dir, so a uid shift strands the files inside it
    systemd.tmpfiles.rules = [ "Z /var/log/suricata - suricata suricata - -" ];

    services.logrotate.settings.suricata = {
      # a space-joined string generates one quoted literal path that matches nothing
      files = [
        "/var/log/suricata/*.log"
        "/var/log/suricata/*.json"
      ];
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
