{config, ...}: let
  colors = config.lib.stylix.colors;
in {
  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    settings = {
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
              };
              "template" = " {{ .UpstreamIcon }}{{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }}  {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }}<#${colors.base05}>  {{ .Staging.String }}</>{{ end }}{{ if gt .StashCount 0 }}  {{ .StashCount }}{{ end }} ";
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
  };
}
