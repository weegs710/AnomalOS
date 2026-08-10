{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;

  # tack rewrites the input's own nixpkgs to ours, so the tree the database was paired with only survives in its checked-in lock.
  pairedRev =
    (builtins.fromJSON (builtins.readFile "${inputs.nix-index-database}/flake.lock")).nodes.nixpkgs.locked.rev;

  nixIndex = inputs.nix-index-database.packages.${system}.nix-index-with-db;

  engine = pkgs.writeText "shop-engine.nix" ''
    import ${../lib/shop/engine.nix} {
      system = "${system}";
      revisionsFile = ${../lib/shop/index/revisions.json};
      indexFile = ${../lib/shop/index/versions.json};
      pinned = "${pairedRev}";
    }
  '';

  unwrappedShop = pkgs.writers.writeNuBin "shop" (builtins.readFile ../lib/shop/shop.nu);
  unwrappedRestock = pkgs.writers.writeNuBin "restock" (builtins.readFile ../lib/shop/tools/restock.nu);
in
{
  # nix itself is left to PATH on purpose: shop must use the caller's nix, not a pinned one.
  shop =
    pkgs.runCommand "shop"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        meta.mainProgram = "shop";
      }
      ''
        makeWrapper ${unwrappedShop}/bin/shop $out/bin/shop \
          --set SHOP_ENGINE ${engine} \
          --prefix PATH : ${lib.makeBinPath [ nixIndex ]}
      '';

  restock =
    pkgs.runCommand "restock"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        meta.mainProgram = "restock";
      }
      ''
        makeWrapper ${unwrappedRestock}/bin/restock $out/bin/restock \
          --prefix PATH : ${
            lib.makeBinPath [
              pkgs.nushell
              pkgs.python3
              pkgs.git
              nixIndex
            ]
          }
      '';
}
