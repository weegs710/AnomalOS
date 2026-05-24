{
  config,
  pkgs,
  ...
}:
{
  users.users.${config.mySystem.user.name}.packages = with pkgs; [
    btop-rocm
  ];

  preservation.preserveAt."/persist".users.${config.mySystem.user.name}.directories = [
    ".config/btop"
  ];
}
