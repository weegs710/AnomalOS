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

          # Debug log
          dbg="/tmp/termfilechooser-debug.log"
          echo "=== $(date) ===" >> "$dbg"
          echo "Args: multiple=$1 directory=$2 save=$3 path=$4 out=$5" >> "$dbg"

          if [ "$save" = "1" ]; then
              # Save mode: use script command to capture --print-last-dir output
              filename=$(basename "$path")
              startdir=$(dirname "$path")
              echo "Save mode: filename=$filename startdir=$startdir" >> "$dbg"

              # Create temp file for script output
              scriptout=$(mktemp)
              echo "Script output file: $scriptout" >> "$dbg"

              # Run superfile in ghostty, using script to capture output
              ghostty --title=termfilechooser -e script -q "$scriptout" -c "superfile --print-last-dir \"$startdir\""

              # Log raw script output
              echo "--- Raw script output ---" >> "$dbg"
              cat "$scriptout" >> "$dbg" 2>&1
              echo "--- End raw output ---" >> "$dbg"

              # Extract directory path from anywhere in output (handles ANSI garbage)
              lastdir=$(grep -oE '/(home|mnt|run|tmp|media)[/A-Za-z0-9_.-]+' "$scriptout" | grep -vE '\.[a-zA-Z0-9]{2,5}$' | tail -1 || true)
              echo "Filtered path result: '$lastdir'" >> "$dbg"

              rm -f "$scriptout"

              # Write full save path to output
              echo "Final lastdir: '$lastdir'" >> "$dbg"
              if [ -n "$lastdir" ]; then
                  echo "''${lastdir}/''${filename}" > "$out"
                  echo "Wrote to out: ''${lastdir}/''${filename}" >> "$dbg"
              else
                  echo "ERROR: lastdir is empty, nothing written to out" >> "$dbg"
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
