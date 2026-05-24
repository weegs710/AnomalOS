{
  config,
  pkgs,
  ...
}:
{
  users.users.${config.mySystem.user.name}.packages = with pkgs; [
    libqalculate
    qalculate-gtk
  ];

  preservation.preserveAt."/persist".users.${config.mySystem.user.name}.directories = [
    ".config/qalculate"
    ".local/share/qalculate"
    ".local/state/qalculate"
  ];
}
