{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  config = mkIf config.mySystem.features.claudeCode {
    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      claude-code
    ];

    environment.shellAliases = {
      cc = "~/bin/claude-launcher";
    };
  };
}
