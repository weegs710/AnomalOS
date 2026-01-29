# Better repl with preloaded functions and libs already loaded
# https://bmcgee.ie/posts/2023/01/nix-and-its-slow-feedback-loop/#how-you-should-use-the-repl
# Usage: nix repl --expr 'import ./repl.nix {}'
#   or:  nix repl --expr 'import ./repl.nix { host = "Rig"; }'
{host ? "Rig", ...}: let
  user = "weegs";
  flake = builtins.getFlake (toString ./.);
  inherit (flake.inputs.nixpkgs) lib;

  # Build attrs for each nixosConfiguration
  hostAttrs = lib.mergeAttrsList (
    map (
      name: let
        cfg = flake.nixosConfigurations.${name}.config;
      in {
        "${name}" = cfg;
        "${name}Opts" = cfg.mySystem;
      }
    ) (lib.attrNames flake.nixosConfigurations)
  );
in
  hostAttrs
  // rec {
    inherit lib;
    inherit (flake) inputs;
    inherit flake host user;
    self = flake;

    # default host shortcuts
    inherit (flake.nixosConfigurations.${host}) pkgs;
    c = flake.nixosConfigurations.${host}.config;
    config = c;
    opts = c.mySystem;

    # home-manager config for the user
    hm = c.home-manager.users.${user};
  }
