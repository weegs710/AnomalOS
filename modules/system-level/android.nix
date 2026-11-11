{
  config,
  pkgs,
  only,
  ...
}:
only.gate { tags = [ "dev" ]; } {
  environment.systemPackages = with pkgs; [
    android-tools
  ];

  preservation.preserveAt."/persist".users.${config.mySystem.user.name}.directories = [
    ".android"
  ];
}
