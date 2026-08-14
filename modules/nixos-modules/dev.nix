{
  config,
  pkgs,
  only,
  ...
}:
let
  ns = pkgs.writeShellApplication {
    name = "ns";
    runtimeInputs = with pkgs; [
      fzf
      nix-search-tv
    ];
    checkPhase = "";
    text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
  };
  dprintConfig = pkgs.writeText "dprint.json" (
    builtins.toJSON {
      "markdown" = { };
      "plugins" = [ "file://${pkgs.dprint-plugins.dprint-plugin-markdown}/plugin.wasm" ];
      "includes" = [ "**/*.md" ];
    }
  );
  dprintmd = pkgs.writeShellApplication {
    name = "dprintmd";
    runtimeInputs = [ pkgs.dprint ];
    # config baked into store -- no per-project dprint.json needed
    text = ''exec dprint fmt --config "${dprintConfig}" --allow-no-files "$@"'';
  };
  claudeLauncher = pkgs.writeScriptBin "claude-launcher" ''
    #!/usr/bin/env nu

    def main [project_name?: string] {
      let projects_dir = $"($env.HOME)/claude-projects/projects"

      if ($project_name | is-empty) {
        print "Usage: ccl <project-name>"
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
in
# gated so a host without the dev tag skips this bundle instead of carrying the toolchain
only.gate { tags = [ "dev" ]; }
{
  programs = {
    tmux.enable = true;
    nix-index.enable = true;
    wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };
    git.enable = true;
    direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
      direnvrcExtra = ''
        warn_timeout=0
        hide_env_diff=true
      '';
    };
  };

  users.users.${config.mySystem.user.name}.packages = with pkgs; [
    cargo
    clippy
    gh
    hyperfine
    hyprls
    jq
    nodejs
    python3
    ripgrep
    rust-analyzer
    rustc
    rustfmt
    uv
    biome
    dprintmd
    nixfmt
    typescript
    typescript-language-server
    vscode-langservers-extracted
    claude-code
    claudeLauncher
  ];

  environment.systemPackages = with pkgs; [
    jujutsu
    ns
  ];

  environment.shellAliases = {
    ccl = "claude-launcher";
  };
}
