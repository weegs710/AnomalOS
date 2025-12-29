{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.desktop {
    programs.waybar.style = lib.mkAfter ''
          * {
              font-family: "FiraCode Nerd Font";
              font-size: 14px;
              color: @base05;
          }

          #tray menu {
              background-color: @base01;
          }

          window#waybar {
              background: transparent;
              border-radius: 0 0 12px 12px;
          }

          #waybar {
              background: transparent;
              border: none;
              border-radius: 0 0 10px 10px;
          }

          #workspaces {
              background: alpha(@base00, 0.75);
              padding: 2px 6px;
              margin-top: 3px;
              margin-bottom: 3px;
              margin-left: 6px;
              margin-right: 6px;
              border-radius: 12px;
          }

          #tray {
              background: alpha(@base00, 0.75);
              padding: 2px 6px;
              margin-top: 3px;
              margin-bottom: 3px;
              margin-left: 6px;
              margin-right: 6px;
              border-radius: 12px;
          }

          #window {
              background: alpha(@base00, 0.75);
              padding: 2px 6px;
              margin-top: 3px;
              margin-bottom: 3px;
              margin-left: 6px;
              margin-right: 6px;
              border-radius: 12px;
          }

          window#waybar.empty #window {
              opacity: 0;
          }

          #network,
          #bluetooth,
          #pulseaudio,
          #clock {
              background: alpha(@base00, 0.75);
              margin-top: 3px;
              margin-bottom: 3px;
              padding: 2px 2px;
          }

          #network {
              margin-left: 6px;
              border-radius: 12px 0 0 12px;
          }

          #bluetooth,
          #pulseaudio {
              border-radius: 0;
          }

          #clock {
              margin-right: 6px;
              border-radius: 0 12px 12px 0;
          }

          #custom-lock,
          #custom-reboot,
          #custom-power {
              background: alpha(@base00, 0.75);
              margin-top: 3px;
              margin-bottom: 3px;
              padding: 2px 2px;
          }

          #custom-lock {
              margin-left: 6px;
              border-radius: 12px 0 0 12px;
          }

          #custom-reboot {
              border-radius: 0;
          }

          #custom-power {
              margin-right: 6px;
              border-radius: 0 12px 12px 0;
          }

          #battery,
          #backlight,
          #custom-temperature,
          #memory,
          #cpu {
              background: transparent;
              margin-top: 3px;
              margin-bottom: 3px;
              padding: 2px 2px;
          }

          #custom-temperature.critical,
          #pulseaudio.muted {
              color: @base08;
              padding-top: 0;
          }

          #bluetooth:hover,
          #network:hover,
          #backlight:hover,
          #battery:hover,
          #pulseaudio:hover,
          #custom-temperature:hover,
          #memory:hover,
          #cpu:hover,
          #clock:hover,
          #custom-lock:hover,
          #custom-reboot:hover,
          #custom-power:hover {
              background: alpha(@base0C, 0.5);
          }

          #workspaces button:hover {
              background: alpha(@base0C, 0.5);
              padding: 2px 8px;
              margin: 0 2px;
              border-radius: 10px;
              border: none;
              outline: none;
              text-shadow: none;
              box-shadow: none;
          }

          #tray > * {
              background: transparent;
          }

          #tray > *:hover {
              background: alpha(@base0C, 0.5);
          }

          .modules-left #workspaces button.active {
              background: transparent;
              color: @base05;
              border-bottom: 3px solid @base0D;
          }

          .modules-center #workspaces button.active {
              background: transparent;
              color: @base05;
              border-bottom: 3px solid @base0D;
          }

          .modules-right #workspaces button.active {
              background: transparent;
              color: @base05;
              border-bottom: 3px solid @base0D;
          }

          #workspaces button {
              background: transparent;
              border: none;
              outline: none;
              color: @base05;
              padding: 2px 8px;
              margin: 0 2px;
              font-weight: bold;
              text-shadow: none;
              box-shadow: none;
          }

          #window {
              font-weight: 500;
              font-style: italic;
          }
        '';
  };
}
