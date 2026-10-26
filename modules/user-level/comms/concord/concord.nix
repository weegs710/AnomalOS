{
  config,
  pkgs,
  inputs,
  ...
}:
let
  username = config.mySystem.user.name;
  concord = inputs.concord.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  users.users.${username}.packages = [
    concord
  ];

  # immutable store symlinks -- options are hard-declared and never edited in-app
  hjem.users.${username}.xdg.config.files = {
    "concord/config.toml".source = ./config.toml;
    "concord/theme.toml".source = ./theme.toml;
  };

  # concord.log sits beside the config and ui_state in the state dir, which CONCORD_TOKEN keeps token-free
  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/concord"
    ".local/state/concord"
  ];
}
