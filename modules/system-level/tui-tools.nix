{
  config,
  pkgs,
  ...
}:
{
  users.users.${config.mySystem.user.name}.packages = with pkgs; [
    btop-rocm
    pulsemixer
    timg
    libqalculate
    qalculate-gtk
  ];

  preservation.preserveAt."/persist".users.${config.mySystem.user.name}.directories = [
    ".config/btop"
    ".config/qalculate"
    ".local/share/qalculate"
    ".local/state/qalculate"
  ];
}
