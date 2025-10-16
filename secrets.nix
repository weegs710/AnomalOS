# secrets.nix
#
# This file defines which SSH keys can decrypt which secrets.
# All secrets are encrypted using age with SSH keys.
#
# To edit a secret: nix run github:ryantm/agenix -- -e <secret-name>.age
# To rekey secrets: nix run github:ryantm/agenix -- -r

let
  # User SSH keys
  weegs = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGK6aaA7gOoqrFHRWpQi5+oQnP3cpknLLesBJHO+lGh weegs@HX99G";

  # System SSH host keys (add more systems as needed)
  HX99G = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDLFiyW4vQi91lrDZ7TSQk5+ldAdJB2YnBYPP7mtLUU9 root@nixos";

  # Groups for easier management
  users = [ weegs ];
  systems = [ HX99G ];
  allKeys = users ++ systems;
in
{
  # Restic backup password
  "secrets/restic-password.age".publicKeys = allKeys;

  # Add more secrets here as needed:
  # "secrets/wifi-password.age".publicKeys = allKeys;
  # "secrets/vpn-config.age".publicKeys = allKeys;
  # "secrets/api-keys.age".publicKeys = allKeys;
}
