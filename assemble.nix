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
      system = "x86_64-linux";
      lib = inputs.nixpkgs.lib;
      inherit (lib.fileset) toList fileFilter;

      weegswarePkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      weegsware = lib.foldl' (acc: f: acc // import f { pkgs = weegswarePkgs; inherit lib; }) { } (
        toList (fileFilter (f: f.hasExt "nix" && !(lib.hasPrefix "_" f.name)) ./weegsware)
      );

      moduleBundles = map (b: import b { inherit inputs; }) (
        toList (fileFilter (f: f.name == "bundle.nix") ./modules)
      );

      # Local-path cursor injected so xdg.nix's `inputs.fft-ivalice-cursor` is unchanged (copyright: stays out of the repo).
      inputs' = inputs // {
        fft-ivalice-cursor = /home/weegs/.local/share/cursor-sources/fft-ivalice-hyprcursor;
      };
    in
    {
      packages.${system} = weegsware;

      nixosConfigurations.HX99G = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inputs = inputs';
          inherit weegsware;
        };
        modules = moduleBundles ++ [
          ./modules/hosts/hx99g-hardware.nix
          ./modules/hosts/hx99g-zfs.nix
          ./modules/hosts/hx99g.nix
        ];
      };
    };
}
