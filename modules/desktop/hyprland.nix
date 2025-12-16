{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.desktop {
    programs = {
      hyprland = {
        enable = true;
        xwayland.enable = true;
      };
      waybar.enable = false;
    };

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
      configPackages = [pkgs.hyprland];
      config = {
        Hyprland = {
          default = [
            "gtk"
            "hyprland"
          ];
          "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
          "org.freedesktop.impl.portal.ScreenCast" = ["hyprland"];
          "org.freedesktop.impl.portal.Screenshot" = ["hyprland"];
        };
      };
    };

    security.pam.services.hyprlock = {};

    systemd.user.services.xdg-desktop-portal.environment = {
      XDG_DESKTOP_PORTAL_DIR = "/run/current-system/sw/share/xdg-desktop-portal/portals";
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

      services.swww = {
        enable = true;
      };

      home.activation.setWallpaper = ''
        ${pkgs.swww}/bin/swww img ~/.local/share/wallpapers/The Rail Unto the Stars.png --resize stretch 2>/dev/null || true
        ln -sf ~/.local/share/wallpapers/The\ Rail\ Unto\ the\ Stars.png ~/.cache/hyprlock-wallpaper
      '';

      home.file.".local/bin/rotate-wallpaper.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          wallpaper_dir="$HOME/.local/share/wallpapers"
          cache_link="$HOME/.cache/hyprlock-wallpaper"

          image=$(ls "$wallpaper_dir"/* 2>/dev/null | shuf -n 1)

          if [ -n "$image" ]; then
            ${pkgs.swww}/bin/swww img "$image" --resize stretch 2>/dev/null || true
            ln -sf "$image" "$cache_link"
          fi
        '';
      };

      systemd.user.services.rotate-wallpaper = {
        Unit = {
          Description = "Rotate wallpaper";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
        };
        Service = {
          ExecStart = "%h/.local/bin/rotate-wallpaper.sh";
          Type = "oneshot";
        };
      };

      systemd.user.timers.rotate-wallpaper = {
        Unit = {
          Description = "Rotate wallpaper at a regular interval";
          Requires = ["rotate-wallpaper.service"];
        };
        Timer = {
          OnBootSec = "42s";
          OnUnitActiveSec = "42s";
          AccuracySec = "1s";
          Persistent = true;
        };
        Install = {
          WantedBy = ["timers.target"];
        };
      };

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
              format = "<span color='#${config.lib.stylix.colors.base0E}'>⏻  </span>";
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
              on-click-right = "hyprctl dispatch exec '[workspace special:control-panel] ghostty -e nmtui'";
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
              on-click-right = "hyprctl dispatch exec '[workspace special:control-panel] ghostty -e bluetui'";
              tooltip = true;
            };
          }
        ];
        style = lib.mkAfter ''
          * {
              font-family: "Terminess Nerd Font";
              font-weight: bold;
              font-size: 18px;
              color: @base04;
          }

          #tray menu {
              background-color: @base01;
          }

          window#waybar {
              background: alpha(@base00, 0.5);
              border-radius: 0 0 25px 25px;
          }

          #waybar {
              background: alpha(@base00, 0.5);
              border: none;
              border-radius: 0 0 10px 10px;
          }

          #workspaces {
              background: alpha(@base00, 0.5);
              padding: 4px 6px;
              margin-top: 6px;
              margin-bottom: 6px;
              margin-left: 6px;
              margin-right: 6px;
              border-radius: 50px;
          }

          #tray {
              background: alpha(@base00, 0.5);
              padding: 4px 6px;
              margin-top: 6px;
              margin-bottom: 6px;
              margin-left: 6px;
              margin-right: 6px;
              border-radius: 50px;
          }

          #window {
              background: alpha(@base00, 0.5);
              padding: 4px 6px;
              margin-top: 6px;
              margin-bottom: 6px;
              margin-left: 6px;
              margin-right: 6px;
              border-radius: 50px;
          }

          #network,
          #bluetooth,
          #pulseaudio,
          #clock {
              background: alpha(@base00, 0.5);
              margin-top: 6px;
              margin-bottom: 6px;
              padding: 4px 2px;
          }

          #network {
              margin-left: 6px;
              border-radius: 50px 0 0 50px;
          }

          #bluetooth,
          #pulseaudio {
              border-radius: 0;
          }

          #clock {
              margin-right: 6px;
              border-radius: 0 50px 50px 0;
          }

          #custom-lock,
          #custom-reboot,
          #custom-power {
              background: alpha(@base00, 0.5);
              margin-top: 6px;
              margin-bottom: 6px;
              padding: 4px 2px;
          }

          #custom-lock {
              margin-left: 6px;
              border-radius: 50px 0 0 50px;
          }

          #custom-reboot {
              border-radius: 0;
          }

          #custom-power {
              margin-right: 6px;
              border-radius: 0 50px 50px 0;
          }

          #battery,
          #backlight,
          #custom-temperature,
          #memory,
          #cpu {
              background: transparent;
              margin-top: 6px;
              margin-bottom: 6px;
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
              background: transparent;
              padding: 2px 8px;
              margin: 0 2px;
              border-radius: 10px;
              border: none;
              outline: none;
              text-shadow: none;
              box-shadow: none;
          }

          #workspaces button.active {
              background: transparent;
              color: @base0C;
              padding: 2px 8px;
              margin: 0 2px;
              border-radius: 10px;
              border: none;
              outline: none;
              text-shadow: none;
              box-shadow: none;
          }

          #workspaces button.active > span {
              color: @base0C;
          }

          #workspaces button {
              background: transparent;
              border: none;
              outline: none;
              color: @base04;
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

      programs.hyprlock = {
        enable = true;
        settings = {
          general = {
            hide_cursor = true;
            grace = 0;
          };

          background = [
            {
              path = "/home/${config.mySystem.user.name}/.cache/hyprlock-wallpaper";
            }
          ];

          input-field = [
            {
              size = "250, 50";
              outline_thickness = 2;
              dots_size = 0.2;
              dots_spacing = 0.35;
              dots_center = true;
              outer_color = "rgb(${config.lib.stylix.colors.base04})";
              inner_color = "rgba(${config.lib.stylix.colors.base00}BF)";
              font_color = "rgb(${config.lib.stylix.colors.base04})";
              fade_on_empty = false;
              placeholder_text = "<span foreground='##${config.lib.stylix.colors.base04}'>Enter Password...</span>";
              hide_input = false;
              position = "0, -100";
              halign = "center";
              valign = "center";
            }
          ];

          shape = [
            {
              size = "350, 120";
              color = "rgba(${config.lib.stylix.colors.base00}BF)";
              rounding = 60;
              border_size = 0;
              position = "0, 150";
              halign = "center";
              valign = "center";
            }
            {
              size = "350, 50";
              color = "rgba(${config.lib.stylix.colors.base00}BF)";
              rounding = 25;
              border_size = 0;
              position = "0, 50";
              halign = "center";
              valign = "center";
            }
          ];

          label = [
            {
              text = ''cmd[update:1000] echo "$(date +"%-I:%M")"'';
              color = "rgb(${config.lib.stylix.colors.base05})";
              font_size = 95;
              font_family = "Terminess Nerd Font";
              position = "0, 150";
              halign = "center";
              valign = "center";
            }
            {
              text = ''cmd[update:60000] echo "$(date +"%A, %B %d")"'';
              color = "rgb(${config.lib.stylix.colors.base04})";
              font_size = 22;
              font_family = "Terminess Nerd Font";
              position = "0, 50";
              halign = "center";
              valign = "center";
            }
          ];
        };
      };

      wayland.windowManager.hyprland = lib.mkIf config.mySystem.features.desktop {
        enable = true;
        settings = {
          "$terminal" = "ghostty";
          "$fileManager" = "ghostty -e yazi";
          "$menu" = "rofi -show drun -show-icons -drun-display-format '{name}'";
          "$webBrowser" = "brave";
          "$mainMod" = "SUPER";
          env = [
            "HYPRCURSOR_THEME,Nordzy-hyprcursors"
            "HYPRCURSOR_SIZE,30"
            "TERMINAL,ghostty"
            "XDG_TERMINAL_EDITOR,ghostty"
          ];
          exec-once = [
            "${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init"
            "kwalletd6 &"
            "tmux new -d waybar &"
            "[workspace 3] steam -silent"
            "[workspace 1] vesktop --start-minimized"
            "hyprctl dispatch workspace 1"
          ];
          general = {
            no_border_on_floating = false;
            gaps_in = 1;
            gaps_out = 2;
            border_size = 1;
            resize_on_border = false;
            allow_tearing = false;
            layout = "dwindle";
          };
          dwindle = {
            pseudotile = true;
            preserve_split = true;
          };
          workspace = [
            "1, gapsin:1, gapsout:2"
            "2, gapsin:1, gapsout:2"
            "3, gapsin:0, gapsout:0, rounding:false"
            "4, gapsin:1, gapsout:2"
            "5, gapsin:1, gapsout:2"
            "special:control-panel, gapsin:2, gapsout:5"
          ];
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
            rounding = 2;
            active_opacity = 0.95;
            inactive_opacity = 0.90;
            shadow = {
              enabled = true;
              range = 8;
              render_power = 4;
            };
            blur = {
              enabled = false;
              size = 2;
              passes = 1;
              new_optimizations = true;
              ignore_opacity = false;
              vibrancy = 0.35;
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
            "$mainMod, 4, workspace, 4"
            "$mainMod, 5, workspace, 5"
            "$mainMod, page_down, workspace, e+1"
            "$mainMod, page_up, workspace, e-1"
            "$mainMod, mouse_down, workspace, e-1"
            "$mainMod, mouse_up, workspace, e+1"
            "$mainMod, grave, togglespecialworkspace, control-panel"
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
            # KWallet password prompts - lock focus to prevent typing into wrong window
            "stayfocused, class:^(org.kde.kwalletd.*)$"
            "stayfocused, class:^(kwalletmanager.*)$"
            "stayfocused, title:^(KDE Wallet Service)(.*)$"
            "stayfocused, title:^(.*)KWallet(.*)$"
            "float, class:^(org.kde.kwalletd.*)$"
            "float, title:^(.*)KWallet(.*)$"

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

            # Workspace: 1 (comms)
            "workspace 1, class:^(vesktop)$"
            "workspace 1, class:^(discord)$"

            # Workspace: 2 (dev)
            "workspace 2, class:^(dev\.zed\.Zed)$"
            "workspace 2, class:^(Zed)$"

            # Workspace: 3 (games)
            "workspace 3, class:^(steam)$"
            "workspace 3, class:^(steam_app_.*)$"
            "workspace 3, class:^(starrail\.exe)$"
            "workspace 3, class:^(moe\.launcher\.the-honkers-railway-launcher)$"
            "workspace 3, title:^(Honkai: Star Rail)$"

            # Workspace: 4 (media)
            "workspace 4, class:^(org\.nickvision\.cavalier)$"
            # "fullscreen, class:^(org\.nickvision\.cavalier)$"
            "workspace 4, class:^(org\.qmmp\.qmmp)$"
            "workspace 4, class:^(com\.stremio\.stremio)$"
            "workspace 4, class:^(chrome-fanduelsportsnetwork\.com__teams_nhl-blue-jackets-Default)$"

            # Workspace: 5 (web)
            "workspace 5, class:^(brave-browser)$"
            "workspace 5, class:^(firefox)$"
            "workspace 5, class:^(chromium-browser)$"
            "focusonactivate, class:^(brave-browser)$"
            "focusonactivate, class:^(firefox)$"
            "focusonactivate, class:^(chromium-browser)$"
            "tile, class:^(steam_app_3564740)$" # Where Winds Meet - force tiled
            "tile, class:^(starrail\.exe)$"

            # Control-panel workspace utilities (must come before dev workspace wezterm rule)
            "workspace special:control-panel, class:^(mpv)$"
            "tile, class:^(pavucontrol)$"
            "workspace special:control-panel, class:^(pavucontrol)$"
            "tile, class:^(org\.pulseaudio\.pavucontrol)$"
            "workspace special:control-panel, class:^(org\.pulseaudio\.pavucontrol)$"
            "tile, title:^(nmtui)$"
            "workspace special:control-panel, title:^(nmtui)$"
            "tile, title:^(bluetui)$"
            "workspace special:control-panel, title:^(bluetui)$"
            "float, class:^(qalculate-gtk)$"
            "workspace special:control-panel, class:^(qalculate-gtk)$"
            "tile, class:^(btop)$"
            "workspace special:control-panel, class:^(btop)$"
            "tile, title:^(btop)$"
            "workspace special:control-panel, title:^(btop)$"
            "float, class:^(cliphist)$"
            "workspace special:control-panel, class:^(cliphist)$"
            "float, class:^(piper)$"
            "workspace special:control-panel, class:^(piper)$"
            "float, class:^(com\.github\.jkotra\.eovpn)$"
            "workspace special:control-panel, class:^(com\.github\.jkotra\.eovpn)$"
            "float, class:^(org\.kde\.kwalletmanager)$"
            "workspace special:control-panel, class:^(org\.kde\.kwalletmanager)$"

            # Workspace: 2 (dev) - ghostty terminals (must come after control-panel utilities)
            "workspace 2, class:^(com\.mitchellh\.ghostty)$"

            # Opacity overrides
            "opacity 1.0 override 1.0 override 1.0 override, class:^(vesktop)$"
            "opacity 1.0 override 1.0 override 1.0 override, class:^(com\.stremio\.stremio)$"
            "opacity 1.0 override 1.0 override 1.0 override, class:^(brave-browser)$"
            "opacity 1.0 override 1.0 override 1.0 override, class:^(starrail\.exe)$"
            "opacity 1.0 override 1.0 override 1.0 override, class:^(chrome-fanduelsportsnetwork\.com__teams_nhl-blue-jackets-Default)$"
            "opacity 1.0 override 1.0 override 1.0 override, class:^(steam_app_.*)$"
            "opacity 1.0 override 1.0 override 1.0 override, class:^(steam)$"
            "opacity 1.0 override 1.0 override 1.0 override, class:^(mpv)$"
            "opacity 1.0 override 1.0 override 1.0 override, class:^(org\.nickvision\.cavalier)$"
          ];
        };
      };
    };
  };
}
