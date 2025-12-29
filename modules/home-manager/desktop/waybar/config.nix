{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.desktop {
    programs.waybar.settings = [
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
  };
}
