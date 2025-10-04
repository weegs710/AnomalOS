{ config, lib, ... }:

with lib;

{
  imports = [
    ./yubikey.nix
    ./firewall.nix
    ./hardening.nix
    ./suricata.nix
  ];

  config = mkIf config.mySystem.features.security {
    # Enable basic security features when security module is enabled
    security = {
      polkit.enable = true;
      rtkit.enable = true;
    };

    services = {
      openssh = {
        enable = true;
        ports = [ 2222 ];
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
          PubkeyAuthentication = true;
          MaxAuthTries = 3;
          ClientAliveInterval = 300;
          ClientAliveCountMax = 2;
          AllowUsers = [ config.mySystem.user.name ];
          X11Forwarding = false;
          PrintMotd = false;
          PermitEmptyPasswords = false;
          KexAlgorithms = [
            "curve25519-sha256@libssh.org"
            "curve25519-sha256"
          ];
          Ciphers = [
            "chacha20-poly1305@openssh.com"
            "aes256-gcm@openssh.com"
            "aes128-gcm@openssh.com"
            "aes256-ctr"
            "aes128-ctr"
          ];
          Macs = [
            "hmac-sha2-512-etm@openssh.com"
            "hmac-sha2-256-etm@openssh.com"
          ];
        };
        openFirewall = false;
      };
    };
  };
}
