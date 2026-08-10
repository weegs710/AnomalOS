{
  inputs,
  config,
  ...
}:
{
  imports = [ inputs.nix-shop.nixosModules.default ];

  programs.shop = {
    enable = true;
    clone = "/home/${config.mySystem.user.name}/repo/nixpkgs.git";
  };
}
