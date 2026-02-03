{...}: {
  perSystem = {pkgs, ...}: let
    logo = ../hjem/fastfetch/nixos.png;
    configFile = pkgs.writeText "fastfetch-config.jsonc" ''
      {
        "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
        "logo": {
          "source": "${logo}",
          "type": "kitty",
          "width": 38,
          "height": 19,
          "padding": {
            "right": 2,
            "top": 2
          }
        },
        "display": {
          "separator": " "
        },
        "modules": [
          "break",
          {
            "type": "title",
            "keyWidth": 10
          },
          "break",
          {
            "type": "os",
            "key": " ",
            "keyColor": "34"
          },
          {
            "type": "kernel",
            "key": " ",
            "keyColor": "34"
          },
          {
            "type": "command",
            "key": "󰦛 ",
            "keyColor": "34",
            "text": "readlink /nix/var/nix/profiles/system | sed -E 's/system-([0-9]+)-link/Generation: \\1/'"
          },
          {
            "type": "command",
            "key": " ",
            "keyColor": "34",
            "text": "nix path-info -S /run/current-system | awk '{printf \"Closure Size: %.2f GB\", $2/1024/1024/1024}'"
          },
          "break",
          {
            "type": "cpu",
            "key": " ",
            "keyColor": "blue"
          },
          {
            "type": "gpu",
            "key": "󰢮 ",
            "keyColor": "blue"
          },
          {
            "type": "memory",
            "key": " ",
            "keyColor": "blue"
          },
          "break",
          {
            "type": "wm",
            "key": " ",
            "keyColor": "34"
          },
          {
            "type": "shell",
            "key": " ",
            "keyColor": "34"
          },
          "break",
          {
            "type": "uptime",
            "key": " ",
            "keyColor": "34",
            "text": "Uptime: "
          },
          {
            "type": "command",
            "key": " ",
            "keyColor": "34",
            "text": "birth_install=$(stat -c %W /); current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days since the last fresh install."
          },
          "break",
          {
            "type": "media",
            "key": "󰝚 ",
            "keyColor": "34"
          },
          "break",
          {
            "type": "custom",
            "format": "\u001b[90m  \u001b[31m  \u001b[32m  \u001b[33m  \u001b[34m  \u001b[35m  \u001b[36m  \u001b[37m "
          },
          "break"
        ]
      }
    '';
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
