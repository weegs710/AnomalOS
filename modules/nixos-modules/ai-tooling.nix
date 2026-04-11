{
  flake.nixosModules.ai-tooling = {
    config,
    lib,
    pkgs,
    ...
  }: let
    claudeLauncher = pkgs.writeScriptBin "claude-launcher" ''
      #!/usr/bin/env nu

      def main [project_name?: string] {
        let projects_dir = $"($env.HOME)/claude-projects/projects"

        if ($project_name | is-empty) {
          print "Usage: cc <project-name>"
          print ""
          print "Available projects:"
          try {
            ls $projects_dir | get name | each { |it| print ($it | path basename) }
          } catch {
            print "No projects found"
          }
          exit 1
        }

        let project_dir = $"($projects_dir)/($project_name)"

        if not ($project_dir | path exists) {
          print $"Error: Project '($project_name)' not found in ($projects_dir)"
          exit 1
        }

        cd $project_dir
        ^claude
      }
    '';
  in {
    config = lib.mkIf config.mySystem.features.aiTooling {
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
