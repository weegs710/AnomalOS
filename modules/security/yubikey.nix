{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  username = config.mySystem.user.name;
  homeDirectory = "/home/${username}";

  # Centralized path definitions
  u2fKeys = "${homeDirectory}/.config/Yubico/u2f_keys";
  sddmConfDir = "/etc/sddm.conf.d";
  autologinConf = "${sddmConfDir}/autologin.conf";
  logFile = "/var/log/yubikey-autologin.log";
  ykmanPath = "/run/current-system/sw/bin/ykman";

  # Shared helper script for all auto-login operations
  autologinScript = pkgs.writeShellScript "yubikey-autologin-helper" ''
    #!/usr/bin/env bash
    set -euo pipefail

    MODE="''${1:-}"

    log() { echo "$(date): $*" >> "${logFile}"; }

    validate_yubikey() {
      [[ ! -x "${ykmanPath}" ]] && { log "ykman not available"; return 1; }
      [[ "$MODE" == "init" ]] && sleep 2  # USB settle time at boot

      local info=$("${ykmanPath}" info 2>/dev/null || echo "")
      [[ ! -f "${u2fKeys}" ]] && { log "No U2F keys file found"; return 1; }
      [[ -s "${u2fKeys}" && -n "$info" ]] && [[ "$info" == *"Security Key"* || "$info" == *"YubiKey"* ]] || { log "YubiKey validation failed"; return 1; }

      log "Validated YubiKey: $(echo "$info" | head -1)"
      return 0
    }

    enable_autologin() {
      log "Enabling auto-login"
      mkdir -p "${sddmConfDir}"
      cat > "${autologinConf}" <<'EOF'
[Autologin]
User=${username}
Session=hyprland
Relogin=true
EOF
      chmod 644 "${autologinConf}"
    }

    disable_autologin() {
      if [[ -f "${autologinConf}" ]]; then
        rm -f "${autologinConf}"
        log "Auto-login disabled"
      else
        log "Auto-login was already disabled"
      fi
    }

    case "$MODE" in
      enable)
        validate_yubikey && enable_autologin || log "Unregistered/invalid YubiKey, auto-login not enabled"
        ;;
      disable)
        disable_autologin
        ;;
      init)
        touch "${logFile}" && chmod 644 "${logFile}"
        log "Auto-login service starting"
        mkdir -p "${sddmConfDir}"
        validate_yubikey && enable_autologin || { log "No registered YubiKey at boot"; disable_autologin; }
        ;;
      *)
        echo "Usage: $0 {enable|disable|init}" >&2
        exit 1
        ;;
    esac
  '';
in

{
  config = mkIf config.mySystem.features.yubikey {
    security.pam.u2f = {
      enable = true;
      control = "sufficient";
      settings = {
        interactive = true;
        authFile = "~/.config/Yubico/u2f_key";
      };
    };

    security.pam.services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
      sddm.u2fAuth = true;
      polkit-1.u2fAuth = true;
    };

    services = {
      udev = {
        packages = [
          pkgs.yubikey-personalization
          pkgs.libu2f-host
          pkgs.yubikey-manager
        ];
        extraRules = ''
          KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0113|0114|0115|0116|0120|0200|0402|0403|0406|0407|0410", TAG+="uaccess", MODE="0664", GROUP="plugdev"
          SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", GROUP="plugdev", MODE="0664"

          # YubiKey auto-login rules
          SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0113|0114|0115|0116|0120|0200|0402|0403|0406|0407|0410", ACTION=="add", TAG+="systemd", ENV{SYSTEMD_WANTS}="yubikey-autologin-enable.service"
          SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0113|0114|0115|0116|0120|0200|0402|0403|0406|0407|0410", ACTION=="remove", TAG+="systemd", ENV{SYSTEMD_WANTS}="yubikey-autologin-disable.service"
        '';
      };
      pcscd.enable = true;
    };

    environment.systemPackages = with pkgs; [
      yubikey-manager
      pam_u2f
    ];

    users.users.${username}.extraGroups = [ "plugdev" ];

    systemd.services = {
      yubikey-autologin-enable = {
        description = "Enable auto-login when registered YubiKey is present";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${autologinScript} enable";
          User = "root";
        };
      };

      yubikey-autologin-disable = {
        description = "Disable auto-login when YubiKey is removed";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${autologinScript} disable";
          User = "root";
        };
      };

      yubikey-autologin-init = {
        description = "Initialize auto-login based on registered YubiKey presence at boot";
        wantedBy = [ "multi-user.target" ];
        before = [ "display-manager.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${autologinScript} init";
          User = "root";
        };
      };
    };
  };
}
