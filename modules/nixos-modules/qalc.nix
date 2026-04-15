{
  flake.nixosModules.qalc = {
    config,
    pkgs,
    ...
  }: {
    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      libqalculate
      qalculate-gtk
    ];
  };
}
