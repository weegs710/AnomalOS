{
  config,
  pkgs,
  inputs,
  ...
}:
let
  username = config.mySystem.user.name;
  wrappedSteam = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.steam;
in
{
  users.users.${username}.packages = [ wrappedSteam ];

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".local/share/Steam"
    ".local/share/umu"
  ];
}
