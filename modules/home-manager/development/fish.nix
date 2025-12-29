{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.fish = {
    enable = true;

    functions = {
      kc-send = {
        description = "Send files to paired KDE Connect device";
        body = ''
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
        '';
      };
    };

    plugins = [
      # fzf integration - fuzzy finder for history, files, git
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }

      # Directory jumping - tracks and jumps to frequently used directories
      {
        name = "z";
        src = pkgs.fishPlugins.z.src;
      }

      # Notifications for long-running commands
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }

      # Colorize man pages
      {
        name = "colored-man-pages";
        src = pkgs.fishPlugins.colored-man-pages.src;
      }

      # Auto-close quotes, parentheses, brackets
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair-fish.src;
      }

      # Remove failed commands from history
      {
        name = "sponge";
        src = pkgs.fishPlugins.sponge.src;
      }

      # Interactive git operations with fzf
      {
        name = "forgit";
        src = pkgs.fishPlugins.forgit.src;
      }
    ];

    interactiveShellInit = ''
      set -g fish_greeting
      set -g fish_color_param b392f0  # base05 light purple
      set -g fish_color_autosuggestion 2f143f  # base03 medium purple
      set -g fish_color_command 66ccff  # base0C cyan - commands
      set -g fish_color_operator ffaa55  # base09 orange - operators like ; & |
      set -g fish_color_end ffaa55  # base09 orange - command terminators
      set -g fish_color_quote aaffaa  # base0B green - strings
      set -g fish_color_error ff6666  # base08 red - errors
      set -g fish_color_normal b392f0  # base05 light purple - normal text
      set -g fish_color_redirection 9999ff  # base0D blue - redirections
      set -g fish_color_option c7aaff  # base06 lighter purple - options/flags
    '';
  };
}
