{
  perSystem = {pkgs, ...}: let
    logo = ../hjem/fastfetch/fetch-logo.webp;
    configFile = pkgs.writeText "fastfetch-config.jsonc" ''
          {
        "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
        "logo": {
          "source": "${logo}",
          "type": "kitty",
          "width": 39,
          "height": 20,
          "padding": {
            "left": 2,
            "right": 2,
            "top": 2
          }
        },
        "display": {
          "separator": " 󰑃 "
        },
        "modules": [
          {
            "type": "title"
          },
          {
            "type": "separator"
          },
          {
            "type": "custom",
            "format": "SYSTEM"
          },
          {
            "type": "os",
            "key": "├"
          },
          {
            "type": "kernel",
            "key": "├"
          },
          {
            "type": "command",
            "key": "├󰦛",
            "text": "readlink /nix/var/nix/profiles/system | sed -E 's/system-([0-9]+)-link/Generation: \\1/'"
          },
          {
            "type": "command",
            "key": "├",
            "text": "nix path-info -S /run/current-system | awk '{printf \"Closure Size: %.2f GB\", $2/1024/1024/1024}'"
          },
          {
            "type": "command",
            "key": "└",
            "text": "birth_install=1750377600; current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days using NixOS."
          },
          {
            "type": "custom",
            "format": "HARDWARE"
          },
          {
            "type": "cpu",
            "key": "├"
          },
          {
            "type": "gpu",
            "key": "├󰢮"
          },
          {
            "type": "memory",
            "key": "└"
          },
          {
            "type": "custom",
            "format": "DESKTOP"
          },
          {
            "type": "wm",
            "key": "├"
          },
          {
            "type": "shell",
            "key": "├"
          },
          {
            "type": "terminal",
            "key": "├"
          },
          {
            "type": "terminalfont",
            "key": "└"
          },
          {
            "type": "custom",
            "format": "MEDIA"
          },
          {
            "type": "display",
            "key": "├󰍹"
          },
          {
            "type": "sound",
            "key": "├󰓃"
          },
          {
            "type": "player",
            "key": "├󰗜"
          },
          {
            "type": "media",
            "key": "└󰝚"
          },
          {
            "type": "custom",
            "format": "\u001b[90m  \u001b[31m  \u001b[32m  \u001b[33m  \u001b[34m  \u001b[35m  \u001b[36m  \u001b[37m "
          }
        ]
      }    '';
    wrappedFastfetch = pkgs.symlinkJoin {
      name = "fastfetch-wrapped";
      paths = [pkgs.fastfetch];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/fastfetch \
          --add-flags "--config ${configFile}"
      '';
      meta.mainProgram = "fastfetch";
    };
  in {
    packages.fastfetch = wrappedFastfetch;
  };
}
