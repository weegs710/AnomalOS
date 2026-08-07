# Per-host include/exclude gate, keyed on the static host descriptor so a bundle decides inclusion without reading evaluated config (avoids module recursion).
lib: host:
let
  anyOf = xs: ys: builtins.any (y: builtins.elem y xs) ys;
  sel =
    x:
    builtins.elem host.name (x.hosts or [ ])
    || anyOf host.tags (x.tags or [ ])
    || builtins.elem host.system (x.systems or [ ]);
  exceptOf = e: sel (if builtins.isList e then { hosts = e; tags = e; } else e);
  match =
    s:
    ((s.hosts or [ ]) ++ (s.tags or [ ]) ++ (s.systems or [ ]) == [ ] || sel s)
    && (s.when or (_: true)) host
    && !((s ? except) && exceptOf s.except);
in
spec: config: lib.mkIf (if builtins.isFunction spec then spec host else match spec) config
