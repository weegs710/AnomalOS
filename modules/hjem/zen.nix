{
  config,
  weegsware,
  ...
}:
let
  username = config.mySystem.user.name;
  wrappedZen = weegsware.zen;
in
{
  users.users.${username}.packages = [ wrappedZen ];

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/zen"
  ];
}
