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
        # --- Top Line ---
        {
          "alignment" = "left";
          "type" = "prompt";
          "segments" = [
            # OS Icon (Grey Diamond)
            {
              "type" = "os";
              "style" = "diamond";
              "leading_diamond" = "";
              "background" = "#${colors.base02}"; # Grey
              "foreground" = "#${colors.base05}"; # Light Cyan Text
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
            # Shell Name (Cyan Powerline)
            {
              "type" = "shell";
              "style" = "powerline";
              "powerline_symbol" = "";
              "background" = "#${colors.base0C}"; # Neon Cyan
              "foreground" = "#${colors.base00}"; # Black Text
              "template" = "  {{ .Name }} ";
            }
            # Root Indicator (Red Powerline)
            {
              "type" = "root";
              "style" = "powerline";
              "powerline_symbol" = "";
              "background" = "#${colors.base08}"; # Red
              "foreground" = "#${colors.base05}";
              "template" = "  admin ";
            }
            # Git (Green Powerline)
            {
              "type" = "git";
              "style" = "powerline";
              "powerline_symbol" = "";
              "background" = "#${colors.base0B}"; # Green
              "foreground" = "#${colors.base00}"; # Black
              "background_templates" = [
                "{{ if or (.Working.Changed) (.Staging.Changed) }}#${colors.base0B}{{ end }}" # Orange
                "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#${colors.base0B}{{ end }}"
                "{{ if gt .Ahead 0 }}#${colors.base0B}{{ end }}" # Purple
                "{{ if gt .Behind 0 }}#${colors.base0B}{{ end }}"
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
        # --- Right Side Status ---
        {
          "alignment" = "right";
          "type" = "prompt";
          "segments" = [
            # Status Check (Green/Red Diamond)
            {
              "type" = "status";
              "style" = "diamond";
              "leading_diamond" = "";
              "background" = "#${colors.base0B}"; # Green
              "foreground" = "#${colors.base00}"; # Black
              "background_templates" = [
                "{{ if gt .Code 0 }}#${colors.base08}{{ end }}" # Red
              ];
              "foreground_templates" = [
                "{{ if gt .Code 0 }}#${colors.base05}{{ end }}" # Light Text
              ];
              "properties" = {"always_enabled" = true;};
              "template" = " {{ if gt .Code 0 }}{{ else }}λ{{ end }} ";
            }
            # Exec Time (Grey Diamond)
            {
              "type" = "executiontime";
              "style" = "diamond";
              "trailing_diamond" = "";
              "background" = "#${colors.base02}"; # Grey
              "foreground" = "#${colors.base05}"; # Text
              "properties" = {
                "style" = "roundrock";
                "threshold" = 0;
              };
              "template" = "  {{ .FormattedMs }} ";
            }
          ];
        }
        # --- Second Line (Date, Path) ---
        {
          "alignment" = "left";
          "type" = "prompt";
          "newline" = true;
          "segments" = [
            # Corner
            {
              "type" = "text";
              "style" = "plain";
              "foreground" = "#${colors.base05}";
              "template" = "╭─";
            }
            # Time
            {
              "type" = "time";
              "style" = "plain";
              "foreground" = "#${colors.base04}"; # Orange
              "properties" = {
                "time_format" = "<#${colors.base0C}> 15:04:05</> <#${colors.base04}>|</> <#${colors.base0C}> 2 Jan, Monday</>";
              };
              "template" = "{{ .CurrentDate | date .Format }} <#${colors.base04}>|</>";
            }
            # Path (Blue Diamond)
            {
              "type" = "path";
              "style" = "diamond";
              "leading_diamond" = "<#${colors.base07}>  </><#${colors.base0D}> in </>"; # Neon Cyan -> Blue
              "foreground" = "#${colors.base0D}"; # Blue
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
        # --- Bottom Line ---
        {
          "alignment" = "left";
          "type" = "prompt";
          "newline" = true;
          "segments" = [
            # Corner
            {
              "type" = "text";
              "style" = "plain";
              "foreground" = "#${colors.base05}";
              "template" = "╰─";
            }
            # Prompt Char
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
