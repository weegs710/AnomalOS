{
  config,
  pkgs,
  inputs,
  packages,
  ...
}:
let
  username = config.mySystem.user.name;
  wrappedZen = packages.zen;
in
{
  users.users.${username}.packages = [ wrappedZen ];

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/zen"
  ];
}
