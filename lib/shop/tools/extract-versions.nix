# Vendored from nixpkgs-multiverse.
# See: https://github.com/fzakaria/nixpkgs-multiverse
{
  revPath,
  system ? builtins.currentSystem,
  attrs ? null,
}:
let
  pkgs = import revPath {
    inherit system;
    config = {
      allowAliases = true;
      allowUnfree = true;
      allowBroken = false;
    };
    overlays = [ ];
  };

  # A revision from 2018 evaluated on a 2026 nix will always have casualties, and one of them must not cost us the other 100k attributes.
  versionOf =
    name:
    let
      attempt = builtins.tryEval (
        let
          drv = pkgs.${name};
          parsed = (builtins.parseDrvName (drv.name or "")).version;
        in
        if !(builtins.isAttrs drv) then
          null
        else if !(drv.type or "" == "derivation") then
          null
        else if drv ? version && builtins.isString drv.version then
          drv.version
        else if parsed != "" then
          parsed
        else
          null
      );
    in
    if attempt.success then attempt.value else null;

  names =
    if attrs != null then
      attrs
    else
      let
        attempt = builtins.tryEval (builtins.attrNames pkgs);
      in
      if attempt.success then attempt.value else [ ];

  present = builtins.filter (n: builtins.hasAttr n pkgs) names;

  resolved = builtins.filter (p: p.value != null) (
    map (n: {
      name = n;
      value = versionOf n;
    }) present
  );
in
builtins.listToAttrs resolved
