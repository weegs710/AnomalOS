{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  config = mkIf config.mySystem.features.desktop {
    programs = {
      hyprland = {
        enable = true;
        xwayland.enable = true;
      };
      hyprlock.enable = true;
      waybar.enable = false;
    };

    services = {
      hypridle.enable = true;
      xserver.enable = false;
    };

    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      grim
      hyprshot
      slurp
      swww
      wl-clipboard
      wl-clip-persist
      wlogout
      wlsunset
    ];

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    home-manager.users.${config.mySystem.user.name} = {
      stylix.targets.hyprland.enable = true;

      programs.waybar = lib.mkIf config.mySystem.features.desktop {
        enable = true;
        settings = [
          {
            layer = "bottom";
            position = "top";
            height = 36;
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
              on-click = "activate";
              format-icons = {
                "active" = " ";
              };
            };
            "custom/lock" = {
              format = "<span color='#${config.lib.stylix.colors.base0C}'>  </span>";
              on-click = "hyprlock";
              tooltip = true;
              tooltip-format = "Lock";
            };
            "custom/reboot" = {
              format = "<span color='#${config.lib.stylix.colors.base0C}'> </span>";
              on-click = "systemctl reboot";
              tooltip = true;
              tooltip-format = "Reboot";
            };
            "custom/power" = {
              format = "<span color='#${config.lib.stylix.colors.base0E}'>⏻ </span>";
              on-click = "systemctl poweroff";
              tooltip = true;
              tooltip-format = "Power Off";
            };
            network = {
              format-wifi = "<span color='#${config.lib.stylix.colors.base0C}'> 󰤨  </span>{signalStrength}% ";
              format-ethernet = "<span color='#${config.lib.stylix.colors.base0B}'>   </span>Wired ";
              tooltip-format = "<span color='#${config.lib.stylix.colors.base0E}'> 󰅧  </span>{bandwidthUpBytes}  <span color='#${config.lib.stylix.colors.base0D}'> 󰅢 </span>{bandwidthDownBytes}";
              format-linked = "<span color='#${config.lib.stylix.colors.base0D}'> 󱘖  </span>{ifname} (No IP) ";
              format-disconnected = "<span color='#${config.lib.stylix.colors.base0E}'>   </span>Disconnected ";
              format-alt = "<span color='#${config.lib.stylix.colors.base0C}'> 󰤨  </span>{essid} ";
              interval = 1;
              on-click-right = "kitty -e nmtui";
              tooltip = true;
            };
            pulseaudio = {
              format = "<span color='#${config.lib.stylix.colors.base0B}'>{icon}</span>{volume}% ";
              format-muted = "<span color='#${config.lib.stylix.colors.base0E}'>  </span>0% ";
              format-icons = {
                headphone = "<span color='#${config.lib.stylix.colors.base0E}'>  </span>";
                hands-free = "<span color='#${config.lib.stylix.colors.base0E}'>  </span>";
                headset = "<span color='#${config.lib.stylix.colors.base0E}'>  </span>";
                phone = "<span color='#${config.lib.stylix.colors.base0C}'>  </span>";
                portable = "<span color='#${config.lib.stylix.colors.base0C}'>  </span>";
                car = "<span color='#${config.lib.stylix.colors.base0D}'>  </span>";
                default = [
                  "<span color='#${config.lib.stylix.colors.base03}'>  </span>"
                  "<span color='#${config.lib.stylix.colors.base0C}'>  </span>"
                  "<span color='#${config.lib.stylix.colors.base0B}'>  </span>"
                ];
              };
              on-click-right = "pavucontrol -t 3";
              on-click = "pactl -- set-sink-mute 0 toggle";
              tooltip = true;
              tooltip-format = "Volume: {volume}%";
            };
            "custom/temperature" = {
              exec = "/run/current-system/sw/bin/sensors | /run/current-system/sw/bin/awk '/edge:/ {gsub(/[+°C]/, \"\", $2); print int($2); exit}'";
              format = "<span color='#${config.lib.stylix.colors.base0D}'>  </span>{}°C ";
              interval = 5;
              tooltip = true;
              tooltip-format = "Current CPU Temperature:  {}°C";
            };
            memory = {
              format = "<span color='#${config.lib.stylix.colors.base0E}'>   </span>{used:0.1f}GB ";
              tooltip = true;
              tooltip-format = "RAM Usage: {used:0.2f}GB/{total:0.2f}GB";
            };
            cpu = {
              format = "<span color='#${config.lib.stylix.colors.base0D}'>   </span>{usage}% ";
              tooltip = true;
            };
            clock = {
              interval = 1;
              format = "<span color='#${config.lib.stylix.colors.base0E}'> 󰥔 </span>{:%I:%M:%S %p} ";
              tooltip = true;
              tooltip-format = "{:L%A %m/%d/%Y}";
            };
            tray = {
              icon-size = 24;
              spacing = 6;
            };
            bluetooth = {
              format = "<span color='#${config.lib.stylix.colors.base0D}'>  </span>{status} ";
              format-connected = "<span color='#${config.lib.stylix.colors.base0D}'>ᛒ</span>{device_alias} ";
              format-connected-battery = "<span color='#${config.lib.stylix.colors.base0D}'>ᛒ</span>{device_alias} {device_battery_percentage}% ";
              tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
              tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
              tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
              tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
              on-click-right = "kitty -e bluetui";
              tooltip = true;
            };
          }
        ];
        style = lib.mkAfter ''
          * {
              font-family: "Terminess Nerd Font";
              font-weight: bold;
              font-size: 18px;
              color: @base07;
          }

          #tray menu {
              background-color: @base01;
          }

          window#waybar {
              background: transparent;
          }

          #waybar {
              background: transparent;
              border: none;
          }

          #workspaces,
          #window,
          #tray {
              background: transparent;
              padding: 4px 6px;
              margin-top: 6px;
              margin-left: 6px;
              margin-right: 6px;
              border-radius: 10px;
          }

          #clock,
          #custom-power {
              background: transparent;
              margin-top: 6px;
              margin-right: 6px;
              padding: 4px 2px;
              border-radius: 0 10px 10px 0;
          }

          #network,
          #custom-lock {
              background: transparent;
              margin-top: 6px;
              margin-left: 6px;
              padding: 4px 2px;
              border-radius: 10px 0 0 10px;
          }

          #custom-reboot,
          #bluetooth,
          #battery,
          #pulseaudio,
          #backlight,
          #custom-temperature,
          #memory,
          #cpu {
              background: transparent;
              margin-top: 6px;
              padding: 4px 2px;
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
          #custom-power:hover,
          #window:hover {
              background: transparent;
          }

          #workspaces button:hover {
              background: alpha(@base0D, 0.2);
              padding: 2px 8px;
              margin: 0 2px;
              border-radius: 10px;
          }

          #workspaces button.active {
              background: @base0D;
              color: @base05;
              padding: 2px 8px;
              margin: 0 2px;
              border-radius: 10px;
          }

          #workspaces button {
              background: transparent;
              border: none;
              color: @base05;
              padding: 2px 8px;
              margin: 0 2px;
              font-weight: bold;
          }

          #window {
              font-weight: 500;
              font-style: italic;
          }
        '';
      };

      wayland.windowManager.hyprland = lib.mkIf config.mySystem.features.desktop {
        enable = true;
        settings = {
          "$terminal" = "kitty";
          "$fileManager" = "kitty -e yazi";
          "$menu" = "rofi -show drun -show-icons -drun-display-format '{name}'";
          "$webBrowser" = "librewolf";
          "$mainMod" = "SUPER";
          env = [
            "HYPRCURSOR_THEME,Nordzy-hyprcursors"
            "HYPRCURSOR_SIZE,30"
            "TERMINAL,kitty"
            "XDG_TERMINAL_EDITOR,kitty"
          ];
          exec-once = [
            "kwalletd6 &"
            "dunst &"
            "tmux new -d waybar &"
            "hyprctl keyword master:orientation top"
            "env STEAM_FRAME_FORCE_CLOSE=1 steam -silent"
            "vesktop --start-minimized"
          ];
          general = {
            no_border_on_floating = true;
            gaps_in = 5;
            gaps_out = 10;
            border_size = 3;
            resize_on_border = false;
            allow_tearing = false;
            layout = "dwindle";
          };
          dwindle = {
            pseudotile = true;
            preserve_split = true;
          };
          master = {
            always_keep_position = false;
            new_status = "master";
            orientation = "top";
            mfact = 0.60;
            new_on_top = true;
          };
          misc = {
            force_default_wallpaper = lib.mkForce (-1);
            disable_hyprland_logo = lib.mkForce false;
          };
          decoration = {
            rounding = 10;
            active_opacity = 0.92;
            inactive_opacity = 0.87;
            shadow = {
              enabled = false;
              range = 8;
              render_power = 4;
            };
            blur = {
              enabled = false;
              size = 8;
              passes = 1;
              new_optimizations = true;
              ignore_opacity = false;
              vibrancy = 0.25;
            };
          };
          input = {
            kb_layout = "us";
            follow_mouse = 1;
            sensitivity = 0;
          };
          device = {
            "name" = "epic-mouse-v1";
            sensitivity = -0.5;
          };
          animations = {
            enabled = 1;
            animation = [
              "windows, 1, 3, myBezier"
              "windowsOut, 1, 5, default, popin 80%"
              "border, 1, 10, default"
              "fade, 1, 5, default"
              "workspaces, 1, 7, default"
              "windowsMove, 1, 5, myBezier"
              "windowsOut, 1, 5, myBezier"
              "fade, 1, 5, default"
              "workspaces,1,4,overshot,slidevert"
            ];
            bezier = [
              "myBezier, 0.05, 0.9, 0.1, 1.05"
              "overshot,0.05,0.9,0.1,1.1"
              "overshot,0.13,0.99,0.29,1.1"
            ];
          };
          bind = [
            "$mainMod, escape, killactive"
            "$mainMod, F, fullscreen"
            "$mainMod, G, togglefloating"
            "$mainMod, P, pseudo, "
            "$mainMod, O, togglesplit, "
            "$mainMod, 1, workspace, 1"
            "$mainMod, 2, workspace, 2"
            "$mainMod, 3, workspace, 3"
            "$mainMod SHIFT, 1, movetoworkspace, 1"
            "$mainMod SHIFT, 2, movetoworkspace, 2"
            "$mainMod SHIFT, 3, movetoworkspace, 3"
            "$mainMod SHIFT, page_down, movetoworkspace, +1"
            "$mainMod SHIFT, page_up, movetoworkspace, -1"
            "$mainMod, page_down, workspace, e+1"
            "$mainMod, page_up, workspace, e-1"
            "$mainMod, grave, togglespecialworkspace, scratchpad"
            "$mainMod SHIFT, grave, movetoworkspacesilent, special:scratchpad"
            "$mainMod, pause, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            ", PRINT, exec, hyprshot -m region --clipboard-only"
            "SHIFT,PRINT, exec, hyprshot -m region -o ~/Pictures"
          ];
          bindel = [
            "$mainMod, home, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
            "$mainMod, end, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ];
          bindl = [
            "SUPER,Super_L, exec, $menu"
            "control alt,delete ,exit"
          ];
          binde = [
            "$mainMod, left, movefocus, l"
            "$mainMod, right, movefocus, r"
            "$mainMod, up, movefocus, u"
            "$mainMod, down, movefocus, d"
            "$mainMod SHIFT, left, movewindow, l"
            "$mainMod SHIFT, right, movewindow, r"
            "$mainMod SHIFT, up, movewindow, u"
            "$mainMod SHIFT, down, movewindow, d"
          ];
          bindr = [
            "control&alt $mainMod, L, exec, hyprlock"
            "control&alt $mainMod, delete, exec, wlogout"
          ];
          bindm = [
            "$mainMod, mouse:272, movewindow"
            "$mainMod, mouse:273, resizewindow"
          ];
          windowrulev2 = [
            # Float common dialog windows (let them position naturally)
            "float, title:^(Open)(.*)$"
            "float, title:^(Save)(.*)$"
            "float, title:^(Save As)(.*)$"
            "float, title:^(Choose)(.*)$"
            "float, title:^(Select)(.*)$"

            # Common dialog patterns
            "float, title:^(Preferences)(.*)$"
            "float, title:^(Settings)(.*)$"
            "float, title:^(Properties)(.*)$"

            # File manager dialogs
            "float, title:^(Create Folder)(.*)$"
            "float, title:^(Rename)(.*)$"
            "float, title:^(Delete)(.*)$"

            # Browser popups
            "float, title:^(Picture-in-Picture)(.*)$"
            "pin, title:^(Picture-in-Picture)(.*)$"

            # Generic popup patterns (catch-all)
            "float, title:^(.*[Dd]ialog.*)$"
            "float, title:^(.*[Pp]opup.*)$"
          ];
        };
      };
    };
  };
}
