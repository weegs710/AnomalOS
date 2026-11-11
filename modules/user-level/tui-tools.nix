{
  config,
  pkgs,
  ...
}:
{
  users.users.${config.mySystem.user.name}.packages =
    [ config.mySystem.btopPackage ]
    ++ (with pkgs; [
      pulsemixer
      timg
      libqalculate
    ]);

  preservation.preserveAt."/persist".users.${config.mySystem.user.name}.directories = [
    ".config/btop"
    ".config/qalculate"
    ".local/share/qalculate"
    ".local/state/qalculate"
  ];
}
