{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.agenix.nixosModules.default ];
  config = {
    users.users.${config.mySystem.user.name}.packages = [
      inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      # age finds plugins on PATH; this one holds the yubikey-bound identity for editing secrets
      pkgs.age-plugin-fido2-hmac
      pkgs.age
    ];

    # Bind mount is removed during activation on tmpfs root; read key from persist directly.
    age.identityPaths = [ "/persist/etc/age/host.key" ];

    age.secrets.tailscale-authkey = {
      file = ../../../secrets/tailscale-authkey.age;
      mode = "0400";
    };

    age.secrets.disroot-xmpp-password = {
      file = ../../../secrets/disroot-xmpp-password.age;
      mode = "0400";
      owner = config.mySystem.user.name;
    };

    age.secrets.github-token = {
      file = ../../../secrets/github-token.age;
      mode = "0400";
      owner = config.mySystem.user.name;
    };
  };
}
