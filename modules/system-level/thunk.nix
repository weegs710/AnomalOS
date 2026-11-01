{
  config,
  weegsware,
  ...
}:
let
  username = config.mySystem.user.name;
in
{
  users.users.${username}.packages = [ weegsware.thunk ];

  # the model out-links are the gc roots for the weights, which are store paths created by `thunk models fetch`
  preservation.preserveAt."/persist".users.${username}.directories = [
    ".local/share/thunk"
    # the old data dir, kept until the model links exist under thunk, since they are gc roots
    ".local/share/vyraj"
  ];
}
