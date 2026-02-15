{
  flake.nixosModules.claude-code = {
    config,
    lib,
    pkgs,
    ...
  }: let
      claudeLauncher = pkgs.writeShellScriptBin "claude-launcher" ''
        #!/usr/bin/env bash

        PROJECTS_DIR="$HOME/claude-projects/projects"

        if [ -z "$1" ]; then
          echo "Usage: cc <project-name>"
          echo "Available projects:"
          ls -1 "$PROJECTS_DIR" 2>/dev/null || echo "No projects found"
          exit 1
        fi

        PROJECT_DIR="$PROJECTS_DIR/$1"

        if [ ! -d "$PROJECT_DIR" ]; then
          echo "Error: Project '$1' not found in $PROJECTS_DIR"
          exit 1
        fi

        cd "$PROJECT_DIR" || exit 1
        exec claude
      '';
  in {
    config = lib.mkIf config.mySystem.features.claudeCode {
        users.users.${config.mySystem.user.name}.packages = with pkgs; [
          claude-code
          claudeLauncher
        ];

        environment.shellAliases = {
          cc = "claude-launcher";
        };
      };
    };
}
