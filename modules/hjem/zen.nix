{
  config,
  pkgs,
  inputs,
  ...
}:
let
  username = config.mySystem.user.name;
  wrappedZen = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.zen;
in
{
  users.users.${username}.packages = [ wrappedZen ];

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/zen"
  ];
}
