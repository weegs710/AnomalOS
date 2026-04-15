{
  flake.nixosModules.timg = {
    config,
    pkgs,
    ...
  }: {
    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      timg
    ];
  };
}
