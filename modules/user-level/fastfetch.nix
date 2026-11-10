{
  config,
  pkgs,
  ...
}:
let
  logo = ../../assets/nunny-triglavian.webp;
  configFile = pkgs.writeText "fastfetch-config.jsonc" ''
        {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": {
        "source": "${logo}",
        "type": "kitty",
        "height": 20,
        "padding": {
          "left": 2,
          "right": 2,
          "top": 2
        }
      },
      "display": {
        "color": {
          "keys": "38;2;255;42;34",
          "title": "38;2;198;204;213",
          "output": "38;2;232;236;241",
          "separator": "38;2;198;204;213"
        },
        "percent": {
          "color": {
            "green": "38;2;198;204;213",
            "yellow": "38;2;255;132;128",
            "red": "38;2;255;42;34"
          }
        },
        "separator": " 󰔰 "
      },
      "modules": [
        {
          "type": "title",
          "color": {
            "user": "38;2;255;42;34",
            "at": "38;2;153;102;102",
            "host": "38;2;198;204;213"
          }
        },
        {
          "type": "separator",
          "outputColor": "38;2;153;61;63"
        },
        {
          "type": "custom",
          "format": "SYSTEM",
          "outputColor": "38;2;238;241;244"
        },
        {
          "type": "os",
          "key": "├"
        },
        {
          "type": "kernel",
          "key": "│└"
        },
        {
          "type": "command",
          "key": "│ └󰦛",
          "text": "readlink /nix/var/nix/profiles/system | sed -E 's/system-([0-9]+)-link/Generation: \\1/'"
        },
        {
          "type": "command",
          "key": "│  └",
          "text": "nix path-info -S /run/current-system | awk '{printf \"Closure Size: %.2f GB\", $2/1024/1024/1024}'"
        },
        {
          "type": "command",
          "key": "└",
          "text": "birth_install=1748145600; current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days using NixOS."
        },
        {
          "type": "custom",
          "format": "HARDWARE",
          "outputColor": "38;2;238;241;244"
        },
        {
          "type": "cpu",
          "key": "├"
        },
        {
          "type": "gpu",
          "key": "├󰢮",
          "hideType": "integrated"
        },
        {
          "type": "memory",
          "key": "└"
        },
        {
          "type": "custom",
          "format": "DESKTOP",
          "outputColor": "38;2;238;241;244"
        },
        {
          "type": "wm",
          "key": "├"
        },
        {
          "type": "shell",
          "key": "└"
        },
        {
          "type": "terminal",
          "key": " └"
        },
        {
          "type": "terminalfont",
          "key": "  └"
        },
        {
          "type": "custom",
          "format": "MEDIA",
          "outputColor": "38;2;238;241;244"
        },
        {
          "type": "display",
          "key": "├󰍹"
        },
        {
          "type": "sound",
          "key": "└󰓃"
        },
        {
          "type": "player",
          "key": " └󰗜"
        },
        {
          "type": "media",
          "key": "  └󰝚"
        },
        {
          "type": "custom",
          "format": "\u001b[90m  \u001b[31m  \u001b[32m  \u001b[33m  \u001b[34m  \u001b[35m  \u001b[36m  \u001b[37m "
        }
      ]
    }    '';
  wrappedFastfetch = pkgs.symlinkJoin {
    name = "fastfetch-wrapped";
    paths = [ pkgs.fastfetch ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/fastfetch \
        --add-flags "--config ${configFile}"
    '';
    meta.mainProgram = "fastfetch";
  };
in
{
  users.users.${config.mySystem.user.name}.packages = [ wrappedFastfetch ];
}
