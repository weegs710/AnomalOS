{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;

  revisionsFile = ../../lib/shop/index/revisions.json;
  indexFile = ../../lib/shop/index/versions.json;

  # tack rewrites the input's own nixpkgs to ours, so the tree the database was paired with only survives in its checked-in lock.
  pairedRev =
    (builtins.fromJSON (builtins.readFile "${inputs.nix-index-database}/flake.lock")).nodes.nixpkgs.locked.rev;

  engine = pkgs.writeText "shop-engine.nix" ''
    import ${../../lib/shop/engine.nix} {
      system = "${system}";
      revisionsFile = ${revisionsFile};
      indexFile = ${indexFile};
      pinned = "${pairedRev}";
    }
  '';

  unwrappedShop = pkgs.writers.writeNuBin "shop" (builtins.readFile ../../lib/shop/shop.nu);
  unwrappedRestock = pkgs.writers.writeNuBin "restock" (builtins.readFile ../../lib/shop/tools/restock.nu);

  # nix itself is left to PATH on purpose: shop must use the system's nix, not a pinned one.
  shop =
    pkgs.runCommand "shop"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        meta.mainProgram = "shop";
      }
      ''
        makeWrapper ${unwrappedShop}/bin/shop $out/bin/shop \
          --set SHOP_ENGINE ${engine} \
          --prefix PATH : ${lib.makeBinPath [ config.programs.nix-index.package ]}
      '';

  restock =
    pkgs.runCommand "restock"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        meta.mainProgram = "restock";
      }
      ''
        makeWrapper ${unwrappedRestock}/bin/restock $out/bin/restock \
          --set SHOP_CLONE ${config.mySystem.shop.clone} \
          --prefix PATH : ${
            lib.makeBinPath [
              pkgs.nushell
              pkgs.python3
              pkgs.git
              config.programs.nix-index.package
            ]
          }
      '';
in
{
  options.mySystem.shop.clone = lib.mkOption {
    type = lib.types.str;
    default = "/home/${config.mySystem.user.name}/repo/nixpkgs.git";
    description = "Bare nixpkgs clone that restock checks revisions out of";
  };

  config.environment.systemPackages = [
    shop
    restock
  ];
}
