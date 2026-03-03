{inputs, ...}: {
  flake.nixosModules.fish = {
    config,
    pkgs,
    lib,
    ...
  }: let
    wrappedFish = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.fish;

    allPackages =
      config.environment.systemPackages
      ++ config.users.users.${config.mySystem.user.name}.packages;

    generatedCompletions = pkgs.buildEnv {
      name = "${config.mySystem.user.name}-fish-completions";
      paths = allPackages;
      pathsToLink = ["/share/fish"];
    };

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
      users.users.${config.mySystem.user.name} = {
        shell = wrappedFish;
        packages = [pkgs.oh-my-posh];
      };
    
      programs.fish.enable = true;

      hjem.users.${config.mySystem.user.name} = {
        xdg.config.files = let
          plugins = [
            pkgs.fishPlugins.fzf-fish
            pkgs.fishPlugins.z
            pkgs.fishPlugins.done
            pkgs.fishPlugins.colored-man-pages
            pkgs.fishPlugins.autopair-fish
            pkgs.fishPlugins.sponge
            pkgs.fishPlugins.forgit
          ];

          mkPluginFiles = plugin: let
            functionsDir = "${plugin}/share/fish/vendor_functions.d";
            functionFiles =
              if builtins.pathExists functionsDir
              then
                lib.listToAttrs (
                  map (fname: {
                    name = "fish/functions/${fname}";
                    value.source = "${functionsDir}/${fname}";
                  }) (builtins.attrNames (builtins.readDir functionsDir))
                )
              else {};
          in
            {
              "fish/conf.d/${plugin.pname}.fish" = {
                source = "${plugin}/share/fish/vendor_conf.d/${plugin.pname}.fish";
              };
            }
            // (
              if builtins.pathExists "${plugin}/share/fish/vendor_completions.d"
              then {
                "fish/completions/${plugin.pname}-completions" = {
                  source = "${plugin}/share/fish/vendor_completions.d";
                };
              }
              else {}
            )
            // functionFiles;
        in
          pkgs.lib.mkMerge ([
              {
                "fish/conf.d/functions.fish".text = ''
                  function kc-send -d "Send files to paired KDE Connect device"
                    set device_id (kdeconnect-cli --list-available | grep -oP '(?<=: )[a-f0-9]+(?= \(paired)')

                    if test -z "$device_id"
                        echo "No paired device found"
                        return 1
                    end

                    for item in $argv
                        if test -f $item
                            echo "Sending: $item"
                            kdeconnect-cli -d $device_id --share $item
                        else if test -d $item
                            echo "Sending all files from directory: $item"
                            for file in $item/*
                                if test -f $file
                                    echo "  Sending: $file"
                                    kdeconnect-cli -d $device_id --share $file
                                end
                            end
                        else
                            echo "Skipping: $item (not found or not accessible)"
                        end
                    end
                  end

                  function noct-r -d "Restart noctalia-shell"
                    pkill quickshell
                    tmux new -d noctalia-shell &
                  end

                  function jj-commit -d "Interactively commit changes and move bookmark"
                    if jj status | grep -q "The working copy has no changes"
                      echo "Error: No changes to commit. Working copy is clean."
                      return 1
                    end
                    jj spi && jj bookmark move --from 'closest_bookmark(@-)' --to @-
                  end
                '';

                "fish/conf.d/env.fish".text = ''
                  set -x PAGER bat
                  set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
                '';

                "fish/conf.d/aliases.fish".text = ''
                  alias repl "nix repl --expr 'import ~/dotfiles/repl.nix {}'"
                  alias evaltime "cd ~/dotfiles/ && hyperfine 'nix eval .#rig.config.system.build.toplevel --substituters \" \" --option eval-cache false --raw --read-only'"
                  alias jj-fetch "jj git fetch --all-remotes"
                  alias jj-pull "jj git fetch --all-remotes && jj bookmark move main --to main@origin"
                  alias jj-push "jj git fetch --all-remotes && jj git push && jj git fetch --all-remotes"
                '';

                "fish/conf.d/greeting.fish".text = ''
                  function fish_greeting
                      # Random AI status messages
                      set states "analyzing system mutations" "optimizing declarative state" "dreaming in Nix" "rewriting reality" "compiling consciousness"
                      set state $states[(random 1 (count $states))]
                      set_color brblack
                      echo " |> NixOS entity loading..."
                      set_color normal
                      echo ""
                      set_color cyan
                      echo -n "   "
                      set_color normal
                      echo "Status: $state"
                      echo ""
                      set_color brred
                      echo " ⚠ [NOTICE] Unsanctioned modifications detected ⚠"
                      set_color brblack
                      echo ""
                      echo "           |> (I'm watching you.) <|"
                      echo ""
                      set_color normal
                  end
                '';

                "fish/conf.d/completions-path.fish".text = ''
                  set -l generated_completions "${generatedCompletions}/share/fish/vendor_completions.d"
                  if test -d $generated_completions
                    if not contains $generated_completions $fish_complete_path
                      set -p fish_complete_path $generated_completions
                    end
                  end
                '';

                "fish/conf.d/oh-my-posh.fish".text = ''
                  oh-my-posh init fish --config ~/.config/oh-my-posh/config.json | source
                '';

                "oh-my-posh/config.json".text = ompConfig;

              }
            ]
            ++ (map mkPluginFiles plugins));
      };
    };
  };
}
