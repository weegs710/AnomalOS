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
        create_help_file=0
      '';

      "xdg-desktop-portal-termfilechooser/superfile-wrapper.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env sh
          # Wrapper script for xdg-desktop-portal-termfilechooser with superfile

          if [ "$6" -ge 4 ]; then
              set -x
          fi

          multiple="$1"
          directory="$2"
          save="$3"
          path="$4"
          out="$5"

          if [ "$save" = "1" ]; then
              # Save mode: use script command to capture --print-last-dir output
              filename=$(basename "$path")
              startdir=$(dirname "$path")

              # Create temp file for script output
              scriptout=$(mktemp)

              # Run superfile in ghostty, using script to capture output
              ghostty --title=termfilechooser -e script -q "$scriptout" -c "superfile --print-last-dir \"$startdir\""

              # Extract the directory path - look for lines starting with /
              lastdir=$(grep '^/' "$scriptout" 2>/dev/null | tail -1 || true)

              # If that didn't work, try the filtering approach
              if [ -z "$lastdir" ]; then
                  lastdir=$(tr -d '\r' < "$scriptout" | grep -v '│' | grep -v '^Script' | grep -v '^[[:space:]]*$' | tail -1 || true)
              fi

              rm -f "$scriptout"

              # Write full save path to output
              if [ -n "$lastdir" ]; then
                  echo "''${lastdir}/''${filename}" > "$out"
              fi
          else
              # Open/select mode: use --chooser-file directly
              ghostty --title=termfilechooser -e superfile --chooser-file="$out" "$path"
          fi
        '';
      };
    };
  };
}
