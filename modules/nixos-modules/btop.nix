{
  config,
  pkgs,
  ...
}:
{
  users.users.${config.mySystem.user.name}.packages = with pkgs; [
    btop-rocm
  ];

  environment.persistence."/persist".users.${config.mySystem.user.name}.directories = [
    ".config/btop"
  ];
}
