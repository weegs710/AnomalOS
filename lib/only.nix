# Per-host include/exclude gate, keyed on the static host descriptor so a bundle decides inclusion without reading evaluated config (avoids module recursion).
lib: validTags: hostNames: host:
let
  join = builtins.concatStringsSep ", ";
  vocab = {
    hosts = hostNames;
    tags = validTags;
    systems = lib.systems.flakeExposed;
  };
  selKeys = builtins.attrNames vocab;
  have = {
    hosts = [ host.name ];
    inherit (host) tags;
    systems = [ host.system ];
  };
  # an ignored key or an unmatched value would silently change which hosts get the config, so both throw
  check =
    where: allowed: s:
    let
      unknown = lib.subtractLists allowed (builtins.attrNames s);
      checkKey =
        k:
        let
          bad = lib.subtractLists vocab.${k} s.${k};
        in
        if !(builtins.isList s.${k}) then
          throw "only: `${k}` in ${where} must be a list"
        else
          bad == [ ] || throw "only: unknown ${k} ${join bad} in ${where}; valid ${k} are ${join vocab.${k}}";
    in
    if !(builtins.isAttrs s) then
      throw "only: ${where} must be an attrset"
    else if unknown != [ ] then
      throw "only: unknown key(s) ${join unknown} in ${where}; valid keys are ${join allowed}"
    else
      builtins.all checkKey (builtins.filter (k: s ? ${k}) selKeys);
  given = s: builtins.filter (k: (s.${k} or [ ]) != [ ]) selKeys;
  # OR within a key, AND across keys, so adding a key narrows the match
  sel = s: builtins.all (k: lib.intersectLists have.${k} s.${k} != [ ]) (given s);
  exceptSpec = e: if builtins.isList e then { tags = e; } else e;
  match =
    s:
    let
      e = exceptSpec s.except;
    in
    assert check "the spec" (selKeys ++ [ "when" "except" ]) s;
    assert !(s ? except) || check "except" selKeys e;
    sel s && (s.when or (_: true)) host && !((s ? except) && given e != [ ] && sel e);
  matches = spec: if builtins.isFunction spec then spec host else match spec;
  # set on the module's own result, not via a wrapper import, which would nest it and reorder list merges
  located =
    file: mod:
    let
      loc = {
        _file = file;
        key = file;
      };
    in
    if builtins.isFunction mod then
      lib.setFunctionArgs (args: mod args // loc) (lib.functionArgs mod)
    else
      mod // loc;
in
{
  gate = spec: config: lib.mkIf (matches spec) config;
  # imports resolve before config does, so they cannot be mkIf'd and must be decided from the host descriptor instead
  imports = spec: modules: if matches spec then modules else [ ];
  # a file shaped { only = spec; module = ...; } is dropped from the import list on a non-matching host, so its options never exist there
  files = lib.concatMap (
    p:
    let
      m = import p;
      extra = lib.subtractLists [ "module" "only" ] (builtins.attrNames m);
    in
    if !(builtins.isAttrs m && m ? only) then
      [ p ]
    else if !(m ? module) || extra != [ ] then
      throw "only: ${toString p} has an `only` header, so its top level must be exactly { only; module; }"
    else if matches m.only then
      [ (located (toString p) m.module) ]
    else
      [ ]
  );
}
