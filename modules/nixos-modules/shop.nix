{
  lib,
  config,
  weegsware,
  ...
}:
{
  options.mySystem.shop.clone = lib.mkOption {
    type = lib.types.str;
    default = "/home/${config.mySystem.user.name}/repo/nixpkgs.git";
    description = "Bare nixpkgs clone that restock checks revisions out of";
  };

  config = {
    environment.systemPackages = [
      weegsware.shop
      weegsware.restock
    ];

    environment.sessionVariables.SHOP_CLONE = config.mySystem.shop.clone;
  };
}
