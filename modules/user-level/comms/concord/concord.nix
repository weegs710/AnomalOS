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

  # immutable store symlink -- text-only config is hard-declared and never edited in-app
  hjem.users.${username}.xdg.config.files."concord/config.toml".source = ./config.toml;

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/concord"
  ];

  # symlink to the tmpfs secret keeps the plaintext token off persisted disk
  systemd.user.services.concord-credential = {
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p -m 700 %h/.local/state/concord";
      ExecStart = "${pkgs.coreutils}/bin/ln -sfn ${config.age.secrets.concord-credential.path} %h/.local/state/concord/credentials.toml";
    };
  };
}
