{
  lib,
  osConfig,
  config,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.desktop {
    xdg.configFile = {
      "xdg-desktop-portal-termfilechooser/config".text = ''
        [filechooser]
        cmd=${config.xdg.configHome}/xdg-desktop-portal-termfilechooser/superfile-wrapper.sh
        default_dir=$HOME
      '';

      "xdg-desktop-portal-termfilechooser/superfile-wrapper.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env sh
          # Wrapper script for xdg-desktop-portal-termfilechooser with superfile
          # See man 5 xdg-desktop-portal-termfilechooser for argument documentation

          set -e

          if [ "$6" -ge 4 ]; then
              set -x
          fi

          multiple="$1"
          directory="$2"
          save="$3"
          path="$4"
          out="$5"

          cmd="superfile"
          termcmd="ghostty --title=termfilechooser -e"

          if [ "$save" = "1" ]; then
              set -- --chooser-file="$out" "$path"
          elif [ "$directory" = "1" ]; then
              set -- --chooser-file="$out" "$path"
          elif [ "$multiple" = "1" ]; then
              set -- --chooser-file="$out" "$path"
          else
              set -- --chooser-file="$out" "$path"
          fi

          command="$termcmd $cmd"
          for arg in "$@"; do
              escaped=$(printf "%s" "$arg" | sed 's/"/\\"/g')
              command="$command \"$escaped\""
          done

          sh -c "$command"
        '';
      };
    };
  };
}
