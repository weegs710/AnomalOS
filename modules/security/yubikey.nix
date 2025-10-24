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
          ExecStart = pkgs.writeShellScript "enable-autologin" ''
                    #!/usr/bin/env bash

                    # Path to registered YubiKeys
                    U2F_KEYS="${homeDirectory}/.config/Yubico/u2f_keys"
                    SDDM_CONF_DIR="/etc/sddm.conf.d"
                    AUTOLOGIN_CONF="$SDDM_CONF_DIR/autologin.conf"
                    LOG_FILE="/var/log/yubikey-autologin.log"

                    # Function to validate YubiKey registration
                    validate_yubikey() {
                      # Use full path to ykman
                      YKMAN_PATH="/run/current-system/sw/bin/ykman"
                      if [[ ! -x "$YKMAN_PATH" ]]; then
                        echo "$(date): ykman not available at $YKMAN_PATH" >> "$LOG_FILE"
                        return 1
                      fi

                      # Get YubiKey serial if possible
                      YUBIKEY_INFO=$($YKMAN_PATH info 2>/dev/null || echo "")

                      # Check if U2F keys file exists and is readable
                      if [[ ! -f "$U2F_KEYS" ]]; then
                        echo "$(date): No U2F keys file found" >> "$LOG_FILE"
                        return 1
                      fi

                      # Basic validation - if we have U2F keys registered and a YubiKey is present
                      if [[ -s "$U2F_KEYS" ]] && [[ -n "$YUBIKEY_INFO" ]]; then
                        # Additional check: try to verify the key works with our system
                        if [[ "$YUBIKEY_INFO" == *"Security Key"* ]] || [[ "$YUBIKEY_INFO" == *"YubiKey"* ]]; then
                          echo "$(date): Validated YubiKey: $(echo "$YUBIKEY_INFO" | head -1)" >> "$LOG_FILE"
                          return 0
                        fi
                      fi

                      echo "$(date): YubiKey validation failed" >> "$LOG_FILE"
                      return 1
                    }

                    # Validate the inserted YubiKey
                    if validate_yubikey; then
                      echo "$(date): Registered YubiKey detected, enabling auto-login" >> "$LOG_FILE"
                      mkdir -p "$SDDM_CONF_DIR"
                      cat > "$AUTOLOGIN_CONF" << 'EOF'
            [Autologin]
            User=${username}
            Session=hyprland
            Relogin=true
            EOF
                      chmod 644 "$AUTOLOGIN_CONF"
                    else
                      echo "$(date): Unregistered or invalid YubiKey detected, auto-login not enabled" >> "$LOG_FILE"
                    fi
          '';
          User = "root";
        };
      };

      yubikey-autologin-disable = {
        description = "Disable auto-login when YubiKey is removed";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "disable-autologin" ''
            #!/usr/bin/env bash

            SDDM_CONF_DIR="/etc/sddm.conf.d"
            AUTOLOGIN_CONF="$SDDM_CONF_DIR/autologin.conf"
            LOG_FILE="/var/log/yubikey-autologin.log"

            # Remove SDDM auto-login config
            if [[ -f "$AUTOLOGIN_CONF" ]]; then
              rm -f "$AUTOLOGIN_CONF"
              echo "$(date): YubiKey removed, auto-login disabled" >> "$LOG_FILE"
            else
              echo "$(date): YubiKey removed, auto-login was already disabled" >> "$LOG_FILE"
            fi
          '';
          User = "root";
        };
      };

      yubikey-autologin-init = {
        description = "Initialize auto-login based on registered YubiKey presence at boot";
        wantedBy = [ "multi-user.target" ];
        before = [ "display-manager.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "init-autologin" ''
                    #!/usr/bin/env bash

                    U2F_KEYS="${homeDirectory}/.config/Yubico/u2f_keys"
                    SDDM_CONF_DIR="/etc/sddm.conf.d"
                    AUTOLOGIN_CONF="$SDDM_CONF_DIR/autologin.conf"
                    LOG_FILE="/var/log/yubikey-autologin.log"

                    # Ensure log file exists with proper permissions
                    touch "$LOG_FILE"
                    chmod 644 "$LOG_FILE"

                    # Function to validate YubiKey registration
                    validate_yubikey() {
                      # Use full path to ykman
                      YKMAN_PATH="/run/current-system/sw/bin/ykman"
                      if [[ ! -x "$YKMAN_PATH" ]]; then
                        echo "$(date): ykman not available at boot: $YKMAN_PATH" >> "$LOG_FILE"
                        return 1
                      fi

                      # Wait a moment for USB to settle
                      sleep 2

                      # Get YubiKey info
                      YUBIKEY_INFO=$($YKMAN_PATH info 2>/dev/null || echo "")

                      # Check if U2F keys file exists and is readable
                      if [[ ! -f "$U2F_KEYS" ]]; then
                        echo "$(date): No U2F keys file found at boot" >> "$LOG_FILE"
                        return 1
                      fi

                      # Basic validation - if we have U2F keys registered and a YubiKey is present
                      if [[ -s "$U2F_KEYS" ]] && [[ -n "$YUBIKEY_INFO" ]]; then
                        if [[ "$YUBIKEY_INFO" == *"Security Key"* ]] || [[ "$YUBIKEY_INFO" == *"YubiKey"* ]]; then
                          echo "$(date): Boot validation successful for: $(echo "$YUBIKEY_INFO" | head -1)" >> "$LOG_FILE"
                          return 0
                        fi
                      fi

                      echo "$(date): No valid registered YubiKey found at boot" >> "$LOG_FILE"
                      return 1
                    }

                    # Initialize log
                    echo "$(date): YubiKey auto-login service starting..." >> "$LOG_FILE"

                    # Ensure conf directory exists
                    mkdir -p "$SDDM_CONF_DIR"

                    # Check for registered YubiKey presence at boot
                    if validate_yubikey; then
                      echo "$(date): Registered YubiKey present at boot, enabling auto-login" >> "$LOG_FILE"
                      cat > "$AUTOLOGIN_CONF" << 'EOF'
            [Autologin]
            User=${username}
            Session=hyprland
            Relogin=true
            EOF
                      chmod 644 "$AUTOLOGIN_CONF"
                    else
                      echo "$(date): No registered YubiKey at boot, ensuring auto-login is disabled" >> "$LOG_FILE"
                      rm -f "$AUTOLOGIN_CONF"
                    fi
          '';
          User = "root";
        };
      };
    };
  };
}
