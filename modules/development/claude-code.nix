{ config, lib, pkgs, ... }:

with lib;

{
  config = mkIf config.mySystem.features.claudeCode {
    # Add Claude Code to user packages
    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      claude-code
    ];

    # Claude Code shell alias
    environment.shellAliases = {
      cc = "~/bin/claude-launcher";
    };

    # This will be configured in the main home.nix when Claude Code is enabled
  };
}