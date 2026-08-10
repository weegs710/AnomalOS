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

      # Local-path cursor injected so xdg.nix's `inputs.fft-ivalice-cursor` is unchanged (copyright: stays out of the repo).
      inputs' = inputs // {
        fft-ivalice-cursor = /home/weegs/.local/share/cursor-sources/fft-ivalice-hyprcursor;
      };

      mkOnly = import ./lib/only.nix lib;

      hosts = {
        HX99G = {
          system = "x86_64-linux";
          tags = [
            "desktop"
            "dev"
            "server"
          ];
          modules = [
            ./modules/hosts/hx99g-hardware.nix
            ./modules/hosts/hx99g-zfs.nix
            ./modules/hosts/hx99g.nix
          ];
        };
      };

      mkHost =
        name:
        {
          system,
          tags ? [ ],
          modules ? [ ],
        }:
        let
          host = { inherit name tags system; };
        in
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inputs = inputs';
            weegsware = weegswareFor system;
            inherit host;
            only = mkOnly host;
          };
          modules = moduleBundles ++ modules;
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

      checks = forSys (
        system:
        lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel) (
          lib.filterAttrs (n: _: hosts.${n}.system == system) nixosConfigurations
        )
      );

      apps = forSys (system: lib.concatMapAttrs mkApp (weegswareFor system));
    };
}
