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

  environment.persistence."/persist".users.${username}.directories = [
    ".local/share/Steam"
    ".local/share/umu"
  ];
}
