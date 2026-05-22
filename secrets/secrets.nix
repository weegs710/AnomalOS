let
  weegs = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGK6aaA7gOoqrFHRWpQi5+oQnP3cpknLLesBJHO+lGh weegs@HX99G";
  HX99G = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAXWwfdmR+kA67bNI93fekq22tJZMqaQUgV93P5YERNf root@HX99G";
in
{
  "tailscale-authkey.age".publicKeys = [
    weegs
    HX99G
  ];
  "discord-token.age".publicKeys = [
    weegs
    HX99G
  ];
  "jellyfin-api-key.age".publicKeys = [
    weegs
    HX99G
  ];
  "radarr-api-key.age".publicKeys = [
    weegs
    HX99G
  ];
  "sonarr-api-key.age".publicKeys = [
    weegs
    HX99G
  ];
}
