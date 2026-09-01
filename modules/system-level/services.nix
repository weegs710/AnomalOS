{
  config,
  lib,
  ...
}:
{
  config = {
    security = {
      polkit.enable = true;
      rtkit.enable = true;
    };

    services = {
      # silently drops any dbus package not also present in system.path
      dbus.packages = lib.mkForce [
        config.services.dbus.dbusPackage
        config.system.path
      ];

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
            "mlkem768x25519-sha256"
            "sntrup761x25519-sha512@openssh.com"
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
