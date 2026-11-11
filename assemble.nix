{
  sprinkles ? import ./lib/sprinkles.nix,
  ...
}@overrides:
sprinkles.new {
  inherit overrides;
  sources.tack = import ./.tack;
  inputs = { tack }: { inherit tack; };
  outputs =
    { tack }:
    let
      inputs = tack;
      lib = inputs.nixpkgs.lib;
      inherit (lib.fileset) toList fileFilter;

      systems = [ "x86_64-linux" ];
      forSys = lib.genAttrs systems;

      pkgsFor =
        system:
        import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      weegswareWith =
        pkgs:
        lib.foldl' (acc: f: acc // import f { inherit pkgs lib inputs; }) { } (
          toList (fileFilter (f: f.hasExt "nix" && !(lib.hasPrefix "_" f.name)) ./weegsware)
        );

      weegswareFor = system: weegswareWith (pkgsFor system);

      moduleBundles = map (b: import b { inherit inputs; }) (
        toList (fileFilter (f: f.name == "bundle.nix") ./modules)
      );

      # closed vocabulary so a typo in a host's tags or an `only` spec fails eval instead of silently skipping
      validTags = [
        "desktop"
        "dev"
        "gaming"
        "lab"
        "server"
      ];

      hostsRoot = ./modules/hosts;

      mkOnly = import ./lib/only.nix lib validTags hostNames;

      readHost =
        name:
        let
          dir = hostsRoot + "/${name}";
          metaFile = dir + "/metadata.nix";
          meta =
            if builtins.pathExists metaFile then
              import metaFile
            else
              throw "host ${name}: no metadata.nix in modules/hosts/${name}/ -- every host directory needs one declaring { system; hostId; tags; }";
          badTags = builtins.filter (t: !(builtins.elem t validTags)) (meta.tags or [ ]);
          validHostId =
            builtins.isString (meta.hostId or null)
            && builtins.match "[0-9a-f]{8}" meta.hostId != null;
          modules = map (f: dir + "/${f}") (
            lib.attrNames (
              lib.filterAttrs (
                n: t: t == "regular" && lib.hasSuffix ".nix" n && n != "metadata.nix" && !(lib.hasPrefix "_" n)
              ) (builtins.readDir dir)
            )
          );
          variants = meta.variants or { };
          variantNames = lib.attrNames variants;
          badVariant = lib.findFirst (
            v:
            let
              x = variants.${v};
            in
            !(builtins.isAttrs x) || builtins.attrNames x != [ "tags" ] || !(builtins.isList x.tags)
          ) null variantNames;
          badVariantTags = lib.subtractLists validTags (lib.concatMap (v: variants.${v}.tags) variantNames);
          variantClashes = lib.intersectLists (map (v: "${name}-${v}") variantNames) hostNames;
        in
        if !(meta ? system) then
          throw "host ${name}: metadata.nix must set `system` (e.g. \"x86_64-linux\")"
        else if !(meta ? tags) then
          throw "host ${name}: metadata.nix must set `tags` (use [ ] for none)"
        else if !(builtins.isList meta.tags) then
          throw "host ${name}: `tags` must be a list"
        else if badTags != [ ] then
          throw "host ${name}: unknown tag(s) ${builtins.concatStringsSep ", " badTags}; valid tags are ${builtins.concatStringsSep ", " validTags}"
        else if !validHostId then
          throw "host ${name}: metadata.nix must set `hostId` to 8 lowercase hex characters, unique per machine -- generate one with: head -c4 /dev/urandom | od -A none -t x4"
        else if modules == [ ] then
          throw "host ${name}: no modules beside metadata.nix -- a host needs at least its hardware config"
        else if !(builtins.isAttrs variants) then
          throw "host ${name}: `variants` must be an attrset like { vm = { tags = [ ... ]; }; }"
        else if badVariant != null then
          throw "host ${name}: variant ${badVariant} must be exactly { tags = [ ... ]; }"
        else if badVariantTags != [ ] then
          throw "host ${name}: unknown tag(s) ${builtins.concatStringsSep ", " badVariantTags} in variants; valid tags are ${builtins.concatStringsSep ", " validTags}"
        else if variantClashes != [ ] then
          throw "host ${name}: variant ${builtins.concatStringsSep ", " variantClashes} has the same name as a host directory"
        else
          {
            inherit (meta) system tags hostId;
            inherit modules variants;
          };

      hostNames = lib.attrNames (
        lib.filterAttrs (n: t: t == "directory" && !(lib.hasPrefix "_" n)) (builtins.readDir hostsRoot)
      );

      hosts = lib.genAttrs hostNames readHost;

      # derived so a host on a new architecture is checked without anyone remembering to widen `systems`
      hostSystems = lib.unique (lib.mapAttrsToList (_: h: h.system) hosts);

      # a variant is its parent plus extra tags under its own attr; it keeps the parent's name so hostName, hostId and `hosts` specs still match
      builds = lib.concatMapAttrs (
        name: h:
        { ${name} = h // { inherit name; }; }
        // lib.mapAttrs' (
          v: extra:
          lib.nameValuePair "${name}-${v}" (
            h
            // {
              inherit name;
              tags = lib.unique (h.tags ++ extra.tags);
            }
          )
        ) h.variants
      ) hosts;

      mkHost =
        attr:
        {
          name,
          system,
          hostId,
          tags ? [ ],
          modules ? [ ],
          ...
        }:
        let
          host = { inherit name tags system; };
          # derived from the host's directory name so identity has one source of truth and a new host cannot silently inherit the default
          identity = {
            mySystem.hostName = name;
            networking.hostId = hostId;
            environment.variables.NH_ATTRP = "nixosConfigurations.${attr}";
          };
        in
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inputs = inputs;
            inherit host;
            only = mkOnly host;
          };
          modules =
            moduleBundles
            ++ modules
            ++ [
              identity
              # built on the host's own pkgs so weegsware and the system share one nixpkgs instance
              ({ pkgs, ... }: { _module.args.weegsware = weegswareWith pkgs; })
            ];
        };

      nixosConfigurations = lib.mapAttrs mkHost builds;

      mkApp =
        name: pkg:
        lib.optionalAttrs (pkg.meta.mainProgram or null != null) {
          ${name} = {
            type = "app";
            program = lib.getExe pkg;
          };
        };
    in
    {
      inherit nixosConfigurations validTags;

      packages = forSys weegswareFor;

      devShells = forSys (system: {
        default = import ./devshell.nix {
          pkgs = pkgsFor system;
          weegsware = weegswareFor system;
        };
      });

      checks = lib.genAttrs hostSystems (
        system:
        let
          # only enforced here -- doing it in `hosts` would let one malformed host dir block every other host's build
          collisions = lib.filterAttrs (_: ns: builtins.length ns > 1) (
            lib.groupBy (n: hosts.${n}.hostId) (lib.attrNames hosts)
          );
          report = lib.concatStringsSep "; " (
            lib.mapAttrsToList (id: ns: "${id} shared by ${lib.concatStringsSep ", " ns}") collisions
          );
        in
        if collisions != { } then
          throw "duplicate hostId(s): ${report} -- every machine needs its own, ZFS uses it to refuse importing a pool owned by another host"
        else
          lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel) (
            lib.filterAttrs (n: _: builds.${n}.system == system) nixosConfigurations
          )
      );

      apps = forSys (system: lib.concatMapAttrs mkApp (weegswareFor system));
    };
}
