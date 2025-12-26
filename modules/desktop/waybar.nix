{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.desktop {
    home-manager.users.${config.mySystem.user.name}.programs.waybar = {
        enable = true;
        settings = [
          {
            layer = "bottom";
            position = "top";
            height = 28;
            spacing = 0;
            modules-left = [
              "tray"
              "hyprland/workspaces"
            ];
            modules-center = [
              "hyprland/window"
            ];
            modules-right = [
              "network"
              "custom/temperature"
              "bluetooth"
              "pulseaudio"
              "clock"
              "custom/lock"
              "custom/reboot"
              "custom/power"
            ];
            "hyprland/workspaces" = {
              disable-scroll = false;
              all-outputs = true;
              format = "{icon}";
              format-icons = {
                "1" = "comms";
                "2" = "dev";
                "3" = "games";
                "4" = "media";
                "5" = "web";
              };
              on-click = "activate";
              sort-by-number = true;
              persistent-workspaces = {
                "*" = 5;
              };
            };
            "custom/lock" = {
              format = "<span color='#F39C12'>  </span>";
              on-click = "hyprlock";
              tooltip = true;
              tooltip-format = "Lock";
            };
            "custom/reboot" = {
              format = "<span color='#E67E22'>  </span>";
              on-click = "systemctl reboot";
              tooltip = true;
              tooltip-format = "Reboot";
            };
            "custom/power" = {
              format = "<span color='#E74C3C'>  </span>";
              on-click = "systemctl poweroff";
              tooltip = true;
              tooltip-format = "Power Off";
            };
            network = {
              format-wifi = "<span color='#00D9FF'> 󰖩 </span>{signalStrength}% ";
              format-ethernet = "<span color='#2ECC71'> 󰈀 </span>Wired ";
              tooltip-format = "<span color='#00D9FF'>   </span>{bandwidthUpBytes}  <span color='#3498DB'> 󰅢 </span>{bandwidthDownBytes}";
              format-linked = "<span color='#3498DB'> 󱘖 </span>{ifname} (No IP) ";
              format-disconnected = "<span color='#E74C3C'> 󰌙 </span>Disconnected ";
              format-alt = "<span color='#00CED1'> 󰖩 </span>{essid} ";
              interval = 1;
              on-click-right = "hyprctl dispatch exec '[workspace special:control-panel] ghostty -e nmtui'";
              tooltip = true;
            };
            pulseaudio = {
              format = "<span color='#2ECC71'>{icon}</span>{volume}% ";
              format-muted = "<span color='#95A5A6'>  </span>0% ";
              format-icons = {
                headphone = "<span color='#00D9FF'> 󰋋 </span>";
                hands-free = "<span color='#00D9FF'> 󰥰 </span>";
                headset = "<span color='#00D9FF'>  </span>";
                phone = "<span color='#00CED1'> 󰏲 </span>";
                portable = "<span color='#00CED1'> 󰥰 </span>";
                car = "<span color='#3498DB'>  </span>";
                default = [
                  "<span color='#95A5A6'>  </span>"
                  "<span color='#00CED1'>  </span>"
                  "<span color='#2ECC71'>  </span>"
                ];
              };
              on-click-right = "pavucontrol -t 3";
              on-click = "pactl -- set-sink-mute 0 toggle";
              tooltip = true;
              tooltip-format = "Volume: {volume}%";
            };
            "custom/temperature" = {
              exec = "/run/current-system/sw/bin/sensors | /run/current-system/sw/bin/awk '/edge:/ {gsub(/[+°C]/, \"\", $2); print int($2); exit}'";
              format = "<span color='#3498DB'>  </span>{}°C ";
              interval = 5;
              tooltip = true;
              tooltip-format = "Current CPU Temperature:  {}°C";
            };
            memory = {
              format = "<span color='#9B59B6'>  </span>{used:0.1f}GB ";
              tooltip = true;
              tooltip-format = "RAM Usage: {used:0.2f}GB/{total:0.2f}GB";
            };
            cpu = {
              format = "<span color='#3498DB'>  </span>{usage}% ";
              tooltip = true;
            };
            clock = {
              interval = 1;
              format = "<span color='#5DADE2'> 󰔠 </span>{:%m/%d/%y %I:%M:%S %p} ";
              tooltip = true;
              tooltip-format = "{:L%A %m/%d/%Y}";
            };
            tray = {
              icon-size = 24;
              spacing = 6;
            };
            bluetooth = {
              format = "<span color='#3498DB'> 󰂯 </span>{status} ";
              format-connected = "<span color='#3498DB'>  </span>{device_alias} ";
              format-connected-battery = "<span color='#3498DB'> 󰥈 </span>{device_alias} {device_battery_percentage}% ";
              tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
              tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
              tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
              tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
              on-click-right = "hyprctl dispatch exec '[workspace special:control-panel] blueman-manager'";
              tooltip = true;
            };
          }
        ];
        style = lib.mkAfter ''
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
  };
}
