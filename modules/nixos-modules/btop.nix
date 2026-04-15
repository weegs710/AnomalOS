{
  flake.nixosModules.btop = {
    config,
    pkgs,
    ...
  }: {
    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      btop-rocm
    ];
  };
}
