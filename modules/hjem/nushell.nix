{inputs, ...}: {
  flake.nixosModules.nushell = {
    config,
    pkgs,
    ...
  }: let
    wrappedNushell = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.nushell;

    colors = {
      base00 = "000000";
      base02 = "2d5b58";
      base04 = "80638e";
      base05 = "e8f6f5";
      base07 = "21d6c9";
      base08 = "ff6b9d";
      base0C = "80638e";
      base0D = "5ec4bc";
    };

    ompConfig = builtins.toJSON {
      "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";
      "version" = 2;
      "console_title_template" = "{{ if .Root }}root @ {{ end }}{{ .Shell }} in {{ .Folder }}";
      "blocks" = [
        {
          "alignment" = "left";
          "type" = "prompt";
          "segments" = [
            {
              "type" = "os";
              "style" = "diamond";
              "leading_diamond" = "";
              "background" = "#${colors.base02}";
              "foreground" = "#${colors.base05}";
              "template" = " {{ if .WSL }} on {{ end }}{{ .Icon }} ";
              "properties" = {
                "alpine" = "";
                "arch" = "";
                "debian" = "";
                "fedora" = "";
                "linux" = "";
                "macos" = "";
                "manjaro" = "";
                "nixos" = "";
                "ubuntu" = "";
                "windows" = "";
              };
            }

            {
              "type" = "shell";
              "style" = "powerline";
              "powerline_symbol" = "";
              "background" = "#${colors.base0C}";
              "foreground" = "#${colors.base00}";
              "template" = "  {{ .Name }} ";
            }

            {
              "type" = "root";
              "style" = "powerline";
              "powerline_symbol" = "";
              "background" = "#${colors.base08}";
              "foreground" = "#${colors.base05}";
              "template" = "  admin ";
            }

            {
              "type" = "git";
              "style" = "powerline";
              "powerline_symbol" = "";
              "background" = "#6cc644";
              "foreground" = "#${colors.base00}";
              "background_templates" = [
                "{{ if or (.Working.Changed) (.Staging.Changed) }}#FFEB3B{{ end }}"
                "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#FFCC80{{ end }}"
                "{{ if gt .Ahead 0 }}#B388FF{{ end }}"
                "{{ if gt .Behind 0 }}#B388FB{{ end }}"
              ];
              "properties" = {
                "branch_icon" = " ";
                "fetch_status" = true;
                "fetch_upstream_icon" = true;
                "fetch_worktree_count" = true;
                "disable_with_jj" = true;
              };
              "template" = " {{ .UpstreamIcon }}{{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }}  {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }}<#${colors.base05}>  {{ .Staging.String }}</>{{ end }}{{ if gt .StashCount 0 }}  {{ .StashCount }}{{ end }} ";
            }
            {
              "type" = "jujutsu";
              "style" = "powerline";
              "powerline_symbol" = "";
              "background" = "#6cc644";
              "foreground" = "#${colors.base00}";
              "background_templates" = [
                "{{ if .Working.Changed }}#FFEB3B{{ end }}"
              ];
              "properties" = {
                "fetch_status" = true;
                "ignore_working_copy" = false;
              };
              "template" = " {{ if .ClosestBookmarks }}{{ .ClosestBookmarks }}{{ else }}{{ .ChangeID }}{{ end }}{{ if .Working.Changed }}  {{ .Working.String }}{{ end }} ";
            }
          ];
        }

        {
          "alignment" = "right";
          "type" = "prompt";
          "segments" = [
            {
              "type" = "status";
              "style" = "diamond";
              "leading_diamond" = "";
              "background" = "#6cc644";
              "foreground" = "#${colors.base00}";
              "background_templates" = [
                "{{ if gt .Code 0 }}#f85149{{ end }}"
              ];
              "foreground_templates" = [
                "{{ if gt .Code 0 }}#${colors.base05}{{ end }}"
              ];
              "properties" = {"always_enabled" = true;};
              "template" = " {{ if gt .Code 0 }}{{ else }}λ{{ end }} ";
            }

            {
              "type" = "executiontime";
              "style" = "diamond";
              "trailing_diamond" = "";
              "background" = "#${colors.base02}";
              "foreground" = "#${colors.base05}";
              "properties" = {
                "style" = "roundrock";
                "threshold" = 0;
              };
              "template" = "  {{ .FormattedMs }} ";
            }
          ];
        }

        {
          "alignment" = "left";
          "type" = "prompt";
          "newline" = true;
          "segments" = [
            {
              "type" = "text";
              "style" = "plain";
              "foreground" = "#${colors.base05}";
              "template" = "╭─";
            }

            {
              "type" = "time";
              "style" = "plain";
              "foreground" = "#${colors.base04}";
              "properties" = {
                "time_format" = "<#${colors.base0C}> 15:04:05</> <#${colors.base04}>|</> <#${colors.base0C}> 2 Jan, Monday</> <#${colors.base04}>|</>";
              };
              "template" = "{{ .CurrentDate | date .Format }}";
            }

            {
              "type" = "path";
              "style" = "diamond";
              "leading_diamond" = "<#${colors.base07}>  </><#${colors.base0D}> in </>";
              "foreground" = "#${colors.base0D}";
              "properties" = {
                "folder_icon" = "  ";
                "folder_separator_icon" = "  ";
                "home_icon" = " ";
                "style" = "agnoster_short";
                "max_depth" = 3;
              };
              "template" = " {{ .Path }} ";
            }
          ];
        }

        {
          "alignment" = "left";
          "type" = "prompt";
          "newline" = true;
          "segments" = [
            {
              "type" = "text";
              "style" = "plain";
              "foreground" = "#${colors.base05}";
              "template" = "╰─";
            }

            {
              "type" = "status";
              "style" = "plain";
              "foreground" = "#${colors.base05}";
              "properties" = {"always_enabled" = true;};
              "template" = "❯ ";
            }
          ];
        }
      ];
      "osc99" = true;
      "transient_prompt" = {
        "background" = "transparent";
        "foreground" = "#${colors.base05}";
        "template" = " ";
      };
      "secondary_prompt" = {
        "background" = "transparent";
        "foreground" = "#${colors.base05}";
        "template" = "╰─❯ ";
      };
    };
  in {
    config = {
      users.users.${config.mySystem.user.name}.packages = [
        pkgs.fzf
        pkgs.oh-my-posh
        pkgs.tldr
        pkgs.zoxide
        wrappedNushell
      ];

      hjem.users.${config.mySystem.user.name}.xdg.config.files = {
        "oh-my-posh/config.json".text = ompConfig;

        "nushell/env.nu".text = ''
          $env.SHELL = (^which nu | str trim)
          $env.PAGER = "bat"
          $env.MANPAGER = "sh -c 'col -bx | bat -l man -p'"

          # Runs directly without save/source pattern (Nushell-specific behavior)
          oh-my-posh init nu --config ~/.config/oh-my-posh/config.json

          $env.CARAPACE_BRIDGES = 'fish,bash,zsh'
          $env.CARAPACE_CACHE = $'($env.HOME)/.cache/carapace'
          $env.CARAPACE_MATCH = '^(?!docker$)' # Disable docker completions due to carapace bug with 'docker build -f <TAB>' See: https://github.com/nushell/nushell/issues/13201

          $env.config = ($env.config? | default {} | merge {
            hooks: {
              pre_prompt: [{ ||
                if (which direnv | is-empty) {
                  return
                }
                direnv export json | from json | default {} | load-env
              }]
            }
          })
        '';

        "nushell/config.nu".text = ''

          def cachix-pin-system [] {
            let store_path = (^nix path-info /run/current-system | str trim)
            print $"Pinning ($store_path) as 'current-system' --keep-revisions 3..."
            # Fixed name so --keep-revisions rotates over revisions of the same pin, not unique pins that never evict.
            ^cachix pin anomalos "current-system" $store_path --keep-revisions 3
            print "Done."
          }

          def nrs-rig [] {
            cd ~/dotfiles/
            nh os switch .#rig
            if $env.LAST_EXIT_CODE == 0 {
              ^nix-store -qR /run/current-system | ^cachix push anomalos
              if $env.LAST_EXIT_CODE == 0 {
                cachix-pin-system
              }
            }
          }

          def nrt-rig [] {
            cd ~/dotfiles/
            nh os test .#rig
          }

          def --wrapped snag [...args: string] {
            nu ~/.config/snag/snag.nu ...$args
          }

          def --wrapped yoink [...args: string] {
            nu ~/.config/yoink/yoink.nu ...$args
          }

          def --wrapped sync-music [...args: string] {
            nu ~/.config/sync-music/sync-music.nu ...$args
          }

          def evaltime [] {
            cd ~/dotfiles/
            hyperfine 'nix eval .#rig.config.system.build.toplevel --substituters " " --option eval-cache false --raw --read-only'
          }

          def recycle [] {
            sudo nix-env --delete-generations +10 --profile /nix/var/nix/profiles/system
            sudo nix-collect-garbage
          }

          def update-deck-pkgs [] {
            cd ~/dotfiles/

            let packages = [
              { name: "steamdeck-dsp",      owner: "Jovian-Experiments", repo: "steamdeck-dsp" },
              { name: "jupiter-fan-control", owner: "Jovian-Experiments", repo: "jupiter-fan-control" },
            ]

            for pkg in $packages {
              let latest = (gh api $"repos/($pkg.owner)/($pkg.repo)/releases/latest" --jq ".tag_name" | str trim)
              let current = (
                open flake.nix
                | lines
                | where { |l| $l | str contains $"github:($pkg.owner)/($pkg.repo)/" }
                | first
                | split row "/"
                | last
                | str replace --all '"' ""
                | str replace ";" ""
                | str trim
              )

              if $latest != $current {
                print $"($pkg.name): ($current) -> ($latest)"
                open flake.nix
                | str replace $"github:($pkg.owner)/($pkg.repo)/($current)" $"github:($pkg.owner)/($pkg.repo)/($latest)"
                | save -f flake.nix
              } else {
                print $"($pkg.name) up to date at ($current)"
              }
            }

            nix flake update steamdeck-dsp jupiter-fan-control
          }

          def jj-pull [] {
            jj git fetch --all-remotes
            jj bookmark move main --to main@origin
          }

          def jj-push [] {
            jj git fetch --all-remotes
            jj git push
            jj git fetch --all-remotes
          }

          def jj-commit [] {
            let status_output = (jj status | complete | get stdout)

            if ($status_output | str contains "The working copy has no changes") {
              print "Error: No changes to commit. Working copy is clean."
              return 1
            }

            jj spi
            jj bookmark move --from 'closest_bookmark(@-)' --to @-
          }

          def noct-r [] {
            if (pkill quickshell | complete).exit_code != 0 { return }
            pkill -x wlsunset
            sleep 500ms
            tmux new-session -d noctalia-shell
          }

          alias repl = nix repl --expr 'import ~/dotfiles/repl.nix {}'
          alias cc = claude-launcher
          alias hex = claude-launcher hex
          alias l = ls -alh
          alias ll = ls -l
          alias closure = nix path-info -Sh /run/current-system
          alias cam-cust = andcam-custom
          alias cam-d = andcam-daemon
          alias cam-list = andcam-list
          alias cam-off = pkill scrcpy
          alias cam-on = andcam-start
          alias gparted = sudo WAYLAND_DISPLAY=$WAYLAND_DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR gparted
          alias jj-fetch = jj git fetch --all-remotes
          alias pixel = ssh -p 8022 u0_a267@100.121.71.20

          def nu_greeting [] {
            let states = [
              "Analyzing system mutations..."
              "Optimizing evaluation times..."
              "Dreaming of derivations..."
              "Refactoring reality..."
              "Compiling consciousness..."
              "Binging vimjoyer content..."
              "Studying iynaix's code..."
            ]
            let state = ($states | shuffle | first)

            print -n $"(ansi cyan)   (ansi reset)"
            print $"Status: ($state)"
          }

          # Zoxide integration (migrated from Fish 'z' plugin)
          export-env {
            $env.config = (
              $env.config?
              | default {}
              | upsert hooks { default {} }
              | upsert hooks.env_change { default {} }
              | upsert hooks.env_change.PWD { default [] }
            )
            let __zoxide_hooked = (
              $env.config.hooks.env_change.PWD | any { try { get __zoxide_hook } catch { false } }
            )
            if not $__zoxide_hooked {
              $env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD | append {
                __zoxide_hook: true,
                code: {|_, dir| ^zoxide add -- $dir}
              })
            }
          }

          def --env --wrapped __zoxide_z [...rest: string] {
            let path = match $rest {
              [] => {'~'},
              [ '-' ] => {'-'},
              [ $arg ] if ($arg | path expand | path type) == 'dir' => {$arg}
              _ => {
                ^zoxide query --exclude $env.PWD -- ...$rest | str trim -r -c "\n"
              }
            }
            cd $path
          }

          def --env --wrapped __zoxide_zi [...rest:string] {
            cd $'(^zoxide query --interactive -- ...$rest | str trim -r -c "\n")'
          }

          alias z = __zoxide_z
          alias zi = __zoxide_zi

          let carapace_completer = {|spans: list<string>|
            CARAPACE_LENIENT=1 carapace $spans.0 nushell ...$spans
            | from json
            | if ($in | default [] | where value =~ '^-.*ERR$' | is-empty) { $in } else { null }
          }

          $env.config = {
            show_banner: false

            hooks: {
              env_change: {
                PWD: [{
                  condition: {|before, after| $before == null}
                  code: {|| nu_greeting }
                }]
              }
            }

            completions: {
              case_sensitive: false
              quick: true
              partial: true
              algorithm: "fuzzy"
              external: {
                enable: true
                max_results: 100
                completer: $carapace_completer
              }
            }

            history: {
              max_size: 100000
              sync_on_enter: true
              file_format: "sqlite"
            }

            # Emacs mode for Fish muscle memory compatibility
            edit_mode: emacs

            table: {
              mode: rounded
              index_mode: always
              show_empty: true
              padding: { left: 1, right: 1 }
            }

            error_style: "fancy"
            use_ansi_coloring: true

            cursor_shape: {
              vi_insert: line
              vi_normal: block
              emacs: line
            }
          }
        '';

        # Empty by design - all initialization in env.nu for consistency
        "nushell/login.nu".text = "";
      };
    };
  };
}
