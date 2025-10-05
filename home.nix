{
  lib,
  pkgs,
  config,
  osConfig,
  ...
}: let
  username = osConfig.mySystem.user.name;
  homeDirectory = "/home/${username}";
in {
  imports = [
    ./modules/claude-code-enhanced
  ];

  # Enable Claude Code enhanced features
  programs.claude-code-enhanced.enable = true;

  # Override Fish shell colors for better visibility
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Fix parameter color (was 16081f - too dark)
      set -g fish_color_param b392f0  # base05 light purple
      # Optional: improve autosuggestion visibility
      set -g fish_color_autosuggestion 2f143f  # base03 medium purple
    '';
  };

  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "25.05";

  # Basic home packages (always included)
  home.packages = with pkgs; [
    alejandra
    alarm-clock-applet
    btop-rocm
    cliphist
    dunst
    fastfetch
    fzf
    gh
    gparted
    grim
    hyprls
    hyprshot
    jq
    kitty
    nh
    nil
    nodejs
    pamixer
    python3
    rofi
    rustc
    slurp
    swww
    tldr
    ueberzugpp
    uv
    wl-clipboard
    wl-clip-persist
    wlogout
    wlsunset
  ];

  home.sessionVariables = {
    EDITOR = "zeditor";
    NIXOS_OZONE_WL = "1";
    TERMINAL = "kitty";
    VISUAL = "zeditor";
    XDG_TERMINAL_EDITOR = "kitty";
  };

  programs.home-manager.enable = true;

  # Claude Code project directory (conditional)
  home.file."claude-projects/.keep" = lib.mkIf osConfig.mySystem.features.claudeCode {
    text = "";
  };

  # Desktop environment configuration (conditional)
  programs.waybar = lib.mkIf osConfig.mySystem.features.desktop {
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
          format = "<span color='#7dcfff'>  </span>";
          on-click = "hyprlock";
          tooltip = true;
          tooltip-format = "Lock";
        };
        "custom/reboot" = {
          format = "<span color='#7dcfff'> </span>";
          on-click = "systemctl reboot";
          tooltip = true;
          tooltip-format = "Reboot";
        };
        "custom/power" = {
          format = "<span color='#b53dff'>⏻ </span>";
          on-click = "systemctl poweroff";
          tooltip = true;
          tooltip-format = "Power Off";
        };
        network = {
          format-wifi = "<span color='#7dcfff'> 󰤨  </span>{essid} ";
          format-ethernet = "<span color='#53b397'>   </span>Wired ";
          tooltip-format = "<span color='#b53dff'> 󰅧  </span>{bandwidthUpBytes}  <span color='#5ca8dc'> 󰅢 </span>{bandwidthDownBytes}";
          format-linked = "<span color='#2082a6'> 󱘖  </span>{ifname} (No IP) ";
          format-disconnected = "<span color='#b53dff'>   </span>Disconnected ";
          format-alt = "<span color='#7dcfff'> 󰤨  </span>{signalStrength}% ";
          interval = 1;
          on-click-right = "kitty -e nmtui";
          tooltip = true;
        };
        pulseaudio = {
          format = "<span color='#53b397'>{icon}</span>{volume}% ";
          format-muted = "<span color='#b53dff'>  </span>0% ";
          format-icons = {
            headphone = "<span color='#a175d4'>  </span>";
            hands-free = "<span color='#a175d4'>  </span>";
            headset = "<span color='#a175d4'>  </span>";
            phone = "<span color='#7dcfff'>  </span>";
            portable = "<span color='#7dcfff'>  </span>";
            car = "<span color='#2082a6'>  </span>";
            default = [
              "<span color='#6b7394'>  </span>"
              "<span color='#7dcfff'>  </span>"
              "<span color='#53b397'>  </span>"
            ];
          };
          on-click-right = "pavucontrol -t 3";
          on-click = "pactl -- set-sink-mute 0 toggle";
          tooltip = true;
          tooltip-format = "Volume: {volume}%";
        };
        "custom/temperature" = {
          exec = "/run/current-system/sw/bin/sensors | /run/current-system/sw/bin/awk '/edge:/ {gsub(/[+°C]/, \"\", $2); print int($2); exit}'";
          format = "<span color='#2082a6'>  </span>{}°C ";
          interval = 5;
          tooltip = true;
          tooltip-format = "Current CPU Temperature:  {}°C";
        };
        memory = {
          format = "<span color='#a175d4'>   </span>{used:0.1f}GB ";
          tooltip = true;
          tooltip-format = "RAM Usage: {used:0.2f}GB/{total:0.2f}GB";
        };
        cpu = {
          format = "<span color='#2082a6'>   </span>{usage}% ";
          tooltip = true;
        };
        clock = {
          interval = 1;
          format = "<span color='#a175d4'> 󰃰 </span>{:%X} ";
          tooltip = true;
          tooltip-format = "{:L%A %m/%d/%Y}";
        };
        tray = {
          icon-size = 24;
          spacing = 6;
        };
        bluetooth = {
          format = "<span color='#5ca8dc'>  </span>{status} ";
          format-connected = "<span color='#5ca8dc'>ᛒ</span>{device_alias} ";
          format-connected-battery = "<span color='#5ca8dc'>ᛒ</span>{device_alias} {device_battery_percentage}% ";
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
          background: alpha(@base00, 0.5);
          padding: 4px 6px;
          margin-top: 6px;
          margin-left: 6px;
          margin-right: 6px;
          border-radius: 10px;
      }

      #clock,
      #custom-power {
          background: alpha(@base00, 0.5);
          margin-top: 6px;
          margin-right: 6px;
          padding: 4px 2px;
          border-radius: 0 10px 10px 0;
      }

      #network,
      #custom-lock {
          background: alpha(@base00, 0.5);
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
          background: alpha(@base00, 0.5);
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
          background: alpha(@base03, 0.5);
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

  wayland.windowManager.hyprland = lib.mkIf osConfig.mySystem.features.desktop {
    enable = true;
    settings = {
      "$terminal" = "kitty";
      "$fileManager" = "thunar";
      "$menu" = "rofi -show drun -show-icons";
      "$webBrowser" = "librewolf";
      "$mainMod" = "SUPER";
      env = [
        "HYPRCURSOR_THEME,Nordzy-hyprcursors"
        "HYPRCURSOR_SIZE,30"
        "TERMINAL,kitty"
        "XDG_TERMINAL_EDITOR,kitty"
      ];
      exec-once = [
        "swww-daemon &"
        "swww img ${config.home.homeDirectory}/dotfiles/modules/desktop/anom3wide.png"
        "dunst &"
        "nfa &"
        "tmux new -d waybar &"
        "hyprctl keyword master:orientation top"
      ];
      general = {
        no_border_on_floating = true;
        gaps_in = 1;
        gaps_out = 2.5;
        border_size = 2;
        "col.active_border" = lib.mkForce "rgb(b53dff)";
        "col.inactive_border" = lib.mkForce "rgba(00000000)";
        resize_on_border = false;
        allow_tearing = false;
        layout = "master";
      };
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
      master = {
        always_keep_position = false;
        new_status = "master";
        orientation = "top";
        mfact = 0.65;
        new_on_top = true;
      };
      misc = {
        force_default_wallpaper = lib.mkForce "-1";
        disable_hyprland_logo = lib.mkForce false;
      };
      decoration = {
        rounding = 0;
        active_opacity = 1;
        inactive_opacity = 1;
        shadow = {
          enabled = true;
          range = 8;
          render_power = 4;
          color = lib.mkForce "rgba(00000033)";
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
}
