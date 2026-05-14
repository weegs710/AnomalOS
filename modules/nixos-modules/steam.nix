{
  config,
  pkgs,
  inputs,
  ...
}:
let
  wrappedSteam = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.steam;
in
{
  users.users.${config.mySystem.user.name}.packages = [ wrappedSteam ];
}
