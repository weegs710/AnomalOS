{
  config,
  pkgs,
  only,
  ...
}:
only.gate { tags = [ "dev" ]; } {
  users.users.${config.mySystem.user.name}.packages = [ pkgs.android-tools ];

  preservation.preserveAt."/persist".users.${config.mySystem.user.name}.directories = [
    ".android"
  ];
}
