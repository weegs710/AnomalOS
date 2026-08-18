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
    ];

    # Bind mount is removed during activation on tmpfs root; read key from persist directly.
    age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

    age.secrets.tailscale-authkey = {
      file = ../../../secrets/tailscale-authkey.age;
      mode = "0400";
    };

    age.secrets.disroot-xmpp-password = {
      file = ../../../secrets/disroot-xmpp-password.age;
      mode = "0400";
      owner = config.mySystem.user.name;
    };

    age.secrets.concord-credential = {
      file = ../../../secrets/concord-credential.age;
      mode = "0400";
      owner = config.mySystem.user.name;
    };

    age.secrets.searx-secret-key = {
      file = ../../../secrets/searx-secret-key.age;
      mode = "0400";
      owner = "searx";
    };

    age.secrets.radarr-api-key = {
      file = ../../../secrets/radarr-api-key.age;
      mode = "0400";
      owner = "recyclarr";
    };

    age.secrets.sonarr-api-key = {
      file = ../../../secrets/sonarr-api-key.age;
      mode = "0400";
      owner = "recyclarr";
    };
  };
}
