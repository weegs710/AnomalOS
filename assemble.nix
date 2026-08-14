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

      weegswareFor =
        system:
        let
          pkgs = pkgsFor system;
        in
        lib.foldl' (acc: f: acc // import f { inherit pkgs lib inputs; }) { } (
          toList (fileFilter (f: f.hasExt "nix" && !(lib.hasPrefix "_" f.name)) ./weegsware)
        );

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

      mkOnly = import ./lib/only.nix lib validTags;

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
        else
          {
            inherit (meta) system tags hostId;
            inherit modules;
          };

      hosts = lib.genAttrs (
        lib.attrNames (
          lib.filterAttrs (n: t: t == "directory" && !(lib.hasPrefix "_" n)) (builtins.readDir hostsRoot)
        )
      ) readHost;

      # derived so a host on a new architecture is checked without anyone remembering to widen `systems`
      hostSystems = lib.unique (lib.mapAttrsToList (_: h: h.system) hosts);

      mkHost =
        name:
        {
          system,
          hostId,
          tags ? [ ],
          modules ? [ ],
        }:
        let
          host = { inherit name tags system; };
          # derived from the host's directory name so identity has one source of truth and a new host cannot silently inherit the default
          identity = {
            mySystem.hostName = name;
            networking.hostId = hostId;
            environment.variables.NH_ATTRP = "nixosConfigurations.${name}";
          };
        in
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inputs = inputs;
            weegsware = weegswareFor system;
            inherit host;
            only = mkOnly host;
          };
          modules = moduleBundles ++ modules ++ [ identity ];
        };

      nixosConfigurations = lib.mapAttrs mkHost hosts;

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
      inherit nixosConfigurations;

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
            lib.filterAttrs (n: _: hosts.${n}.system == system) nixosConfigurations
          )
      );

      apps = forSys (system: lib.concatMapAttrs mkApp (weegswareFor system));
    };
}
