# Better repl with preloaded config and libs.
# https://bmcgee.ie/posts/2023/01/nix-and-its-slow-feedback-loop/#how-you-should-use-the-repl
# Usage: nix repl --expr 'import ./repl.nix {}'
#   or:  nix repl --expr 'import ./repl.nix { host = "HX99G"; }'
{
  host ? "HX99G",
  ...
}:
let
  inputs = import ./.tack;
  inherit (inputs.nixpkgs) lib;
  hosts = import ./assemble.nix;

  # Build attrs for each host: <name> = config, <name>Opts = mySystem
  hostAttrs = lib.mergeAttrsList (
    map (
      name:
      let
        cfg = hosts.${name}.config;
      in
      {
        "${name}" = cfg;
        "${name}Opts" = cfg.mySystem;
      }
    ) (lib.attrNames hosts)
  );
in
hostAttrs
// rec {
  inherit
    lib
    inputs
    host
    hosts
    ;
  user = "weegs";

  # default host shortcuts
  inherit (hosts.${host}) pkgs;
  c = hosts.${host}.config;
  config = c;
  opts = c.mySystem;
}
