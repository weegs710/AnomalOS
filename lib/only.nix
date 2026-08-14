# Per-host include/exclude gate, keyed on the static host descriptor so a bundle decides inclusion without reading evaluated config (avoids module recursion).
lib: validTags: host:
let
  anyOf = xs: ys: builtins.any (y: builtins.elem y xs) ys;
  sel =
    x:
    builtins.elem host.name (x.hosts or [ ])
    || anyOf host.tags (x.tags or [ ])
    || builtins.elem host.system (x.systems or [ ]);
  exceptOf = e: sel (if builtins.isList e then { hosts = e; tags = e; } else e);
  badTags =
    s:
    builtins.filter (x: !(builtins.elem x validTags)) (
      (s.tags or [ ])
      ++ (if (s ? except) && builtins.isList s.except then s.except else (s.except.tags or [ ]))
    );
  checkTags =
    s:
    let
      bad = badTags s;
    in
    if bad == [ ] then
      s
    else
      throw "only: unknown tag(s) ${builtins.concatStringsSep ", " bad}; valid tags are ${builtins.concatStringsSep ", " validTags}";
  match =
    s':
    let
      s = checkTags s';
    in
    ((s.hosts or [ ]) ++ (s.tags or [ ]) ++ (s.systems or [ ]) == [ ] || sel s)
    && (s.when or (_: true)) host
    && !((s ? except) && exceptOf s.except);
  matches = spec: if builtins.isFunction spec then spec host else match spec;
in
{
  gate = spec: config: lib.mkIf (matches spec) config;
  # imports resolve before config does, so they cannot be mkIf'd and must be decided from the host descriptor instead
  imports = spec: modules: if matches spec then modules else [ ];
}
