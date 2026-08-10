{
  pkgs,
  lib,
  config,
  weegsware,
  ...
}:
let
  # The packages output stays generic for `nix run`; only the installed copy knows where this machine's clone lives.
  restock =
    pkgs.runCommand "restock"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        meta.mainProgram = "restock";
      }
      ''
        makeWrapper ${weegsware.restock}/bin/restock $out/bin/restock \
          --set SHOP_CLONE ${config.mySystem.shop.clone}
      '';
in
{
  options.mySystem.shop.clone = lib.mkOption {
    type = lib.types.str;
    default = "/home/${config.mySystem.user.name}/repo/nixpkgs.git";
    description = "Bare nixpkgs clone that restock checks revisions out of";
  };

  config.environment.systemPackages = [
    weegsware.shop
    restock
  ];
}
