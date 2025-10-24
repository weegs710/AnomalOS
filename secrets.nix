# SSH key mappings for age-encrypted secrets

let
  weegs = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGK6aaA7gOoqrFHRWpQi5+oQnP3cpknLLesBJHO+lGh weegs@HX99G";
  HX99G = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDLFiyW4vQi91lrDZ7TSQk5+ldAdJB2YnBYPP7mtLUU9 root@nixos";
  users = [ weegs ];
  systems = [ HX99G ];
  allKeys = users ++ systems;
in
{
  "secrets/restic-password.age".publicKeys = allKeys;
}
