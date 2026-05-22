{
  config,
  pkgs,
  inputs,
  ...
}:
let
  weegs = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGK6aaA7gOoqrFHRWpQi5+oQnP3cpknLLesBJHO+lGh weegs@HX99G";
  HX99G = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAXWwfdmR+kA67bNI93fekq22tJZMqaQUgV93P5YERNf root@HX99G";
  users = [ weegs ];
  systems = [ HX99G ];
  allKeys = users ++ systems;
in
{
  imports = [ inputs.agenix.nixosModules.default ];
  config = {
    users.users.${config.mySystem.user.name}.packages = [
      inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # Bind mount is removed during activation on tmpfs root; read key from persist directly.
    age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

    age.secrets.tailscale-authkey = {
      file = ../../secrets/tailscale-authkey.age;
      mode = "0400";
    };

    # User-owned so the endcord bootstrap activation script reads it without privilege escalation.
    age.secrets.discord-token = {
      file = ../../secrets/discord-token.age;
      mode = "0400";
      owner = config.mySystem.user.name;
    };

    age.secrets.radarr-api-key = {
      file = ../../secrets/radarr-api-key.age;
      mode = "0400";
      owner = "recyclarr";
    };

    age.secrets.sonarr-api-key = {
      file = ../../secrets/sonarr-api-key.age;
      mode = "0400";
      owner = "recyclarr";
    };
  };
}
