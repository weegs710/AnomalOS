{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
in
{
  users.users.${username}.extraGroups = [ "adbusers" ];

  environment.systemPackages = with pkgs; [
    android-tools
  ];
}
