{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.desktop {
  stylix.targets.hyprland.enable = true;

  services.swww = {
    enable = true;
  };

  systemd.user.services.set-wallpaper = {
    Unit = {
      Description = "Set initial Hyprland wallpaper";
      After = ["swww.service"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = let
        script = pkgs.writeShellScript "set-wallpaper" ''
          # Wait for swww daemon to be ready
          for i in {1..30}; do
            if ${pkgs.swww}/bin/swww query &>/dev/null; then
              break
            fi
            sleep 0.5
          done

          # Set wallpaper
          ${pkgs.swww}/bin/swww img ~/.local/share/wallpapers/borg-head.webp --resize stretch 2>/dev/null || true
          ln -sf ~/.local/share/wallpapers/borg-head.webp ~/.cache/hyprlock-wallpaper
        '';
      in "${script}";
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  home.file.".local/bin/rotate-wallpaper.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      wallpaper_dir="$HOME/.local/share/wallpapers"
      cache_link="$HOME/.cache/hyprlock-wallpaper"

      mapfile -t wallpapers < <(find "$wallpaper_dir" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \))

      if [ ''${#wallpapers[@]} -gt 0 ]; then
        image="''${wallpapers[RANDOM % ''${#wallpapers[@]}]}"

        ${pkgs.swww}/bin/swww img "$image" \
          --resize stretch \
          --transition-type grow \
          --transition-duration 2 \
          2>/dev/null || true

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
      Description = "Rotate wallpaper every 15 minutes";
      Requires = ["rotate-wallpaper.service"];
    };
    Timer = {
      OnBootSec = "2m";
      OnUnitActiveSec = "15m";
      AccuracySec = "1m";
      Persistent = true;
    };
    Install = {
      WantedBy = ["timers.target"];
    };
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
          path = "/home/${osConfig.mySystem.user.name}/.cache/hyprlock-wallpaper";
        }
      ];

      input-field = [
        {
          size = "250, 50";
          outline_thickness = 2;
          dots_size = 0.2;
          dots_spacing = 0.35;
          dots_center = true;
          outer_color = "rgb(${osConfig.lib.stylix.colors.base04})";
          inner_color = "rgba(${osConfig.lib.stylix.colors.base00}BF)";
          font_color = "rgb(${osConfig.lib.stylix.colors.base04})";
          fade_on_empty = false;
          placeholder_text = "<span foreground='##${osConfig.lib.stylix.colors.base04}'>Enter Password...</span>";
          hide_input = false;
          position = "0, -100";
          halign = "center";
          valign = "center";
        }
      ];

      shape = [
        {
          size = "350, 120";
          color = "rgba(${osConfig.lib.stylix.colors.base00}BF)";
          rounding = 60;
          border_size = 0;
          position = "0, 150";
          halign = "center";
          valign = "center";
        }
        {
          size = "350, 50";
          color = "rgba(${osConfig.lib.stylix.colors.base00}BF)";
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
          color = "rgb(${osConfig.lib.stylix.colors.base05})";
          font_size = 95;
          font_family = "Terminess Nerd Font";
          position = "0, 150";
          halign = "center";
          valign = "center";
        }
        {
          text = ''cmd[update:60000] echo "$(date +"%A, %B %d")"'';
          color = "rgb(${osConfig.lib.stylix.colors.base04})";
          font_size = 22;
          font_family = "Terminess Nerd Font";
          position = "0, 50";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  wayland.windowManager.hyprland = lib.mkIf osConfig.mySystem.features.desktop {
    enable = true;
    settings = {
      "$terminal" = "ghostty";
      "$fileManager" = "ghostty -e yazi";
      "$menu" = "rofi -show drun -show-icons -drun-display-format '{name}'";
      "$webBrowser" = "brave";
      "$mainMod" = "SUPER";
      monitor = [
        "HDMI-A-2, 2560x1440@144, 0x0, 1"
        ", preferred, auto, 1"
      ];
      env = [
        "XCURSOR_THEME,oreo_axion-magenta_cursors"
        "XCURSOR_SIZE,30"
        "TERMINAL,ghostty"
        "XDG_TERMINAL_EDITOR,ghostty"
      ];
      exec-once = [
        "${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init"
        "kwalletd6 &"
        "hyprctl dispatch workspace 1"
      ];
      general = {
        no_border_on_floating = false;
        gaps_in = 3;
        gaps_out = 6;
        border_size = 3;
        resize_on_border = false;
        allow_tearing = false;
        layout = "dwindle";
        "col.active_border" = lib.mkForce "rgb(${osConfig.lib.stylix.colors.base0D})";
        "col.inactive_border" = lib.mkForce "rgb(${osConfig.lib.stylix.colors.base0C})";
      };
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
      workspace = [
        "1, gapsin:3, gapsout:6"
        "2, gapsin:3, gapsout:6"
        "3, gapsin:0, gapsout:0, rounding:false"
        "4, gapsin:3, gapsout:6"
        "5, gapsin:3, gapsout:6"
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
        vrr = 1;
      };
      decoration = {
        rounding = 10;
        active_opacity = 0.80;
        inactive_opacity = 0.80;
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
        "$mainMod, F1, exec, vesktop"
        "$mainMod, F2, exec, zeditor"
        "$mainMod, F3, exec, steam"
        "$mainMod, F4, exec, euphonica"
        "$mainMod SHIFT, F4, exec, flatpak run com.stremio.Stremio"
        "$mainMod, F5, exec, brave"
        "$mainMod, F6, exec, [workspace special:control-panel] ghostty -e btop"
        "$mainMod, Return, exec, $terminal"
        "$mainMod, Space, exec, ghostty -e yazi"
        "$mainMod SHIFT, Space, exec, thunar"
        "$mainMod, Backspace, submap, resize"
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod, page_down, workspace, e+1"
        "$mainMod, page_up, workspace, e-1"
        "$mainMod, mouse_down, workspace, e-1"
        "$mainMod, mouse_up, workspace, e+1"
        "$mainMod, grave, togglespecialworkspace, control-panel"
        "$mainMod, pause, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", PRINT, exec, hyprshot -m region --clipboard-only"
        "SHIFT, PRINT, exec, hyprshot -m region -o ~/Pictures"
        "CTRL, PRINT, exec, hyprshot -m window --clipboard-only"
      ];
      bindel = [
        "$mainMod, home, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        "$mainMod, end, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ];
      bindl = [
        "SUPER,Super_L, exec, $menu"
        "CTRL ALT, delete, exec, wlogout"
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
        "CTRL_ALT, L, exec, hyprlock"
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

        # Where Winds Meet - force fullscreen and prevent the game from toggling fullscreen itself.
        "fullscreen, class:^(steam_app_3564740)$"
        "suppressevent fullscreen, class:^(steam_app_3564740)$"

        # Workspace: 4 (media)
        "workspace 4, class:^(io\.github\.htkhiem\.Euphonica)$"
        # "workspace 4, class:^(org\.nickvision\.cavalier)$"
        # "fullscreen, class:^(org\.nickvision\.cavalier)$"
        "workspace 4, class:^(com\.stremio\.stremio)$"
        "workspace 4, class:^(chrome-fanduelsportsnetwork\.com__teams_nhl-blue-jackets-Default)$"

        # Workspace: 5 (web)
        "workspace 5, class:^(brave-browser)$"
        "workspace 5, class:^(firefox)$"
        "workspace 5, class:^(chromium-browser)$"
        "focusonactivate, class:^(brave-browser)$"
        "focusonactivate, class:^(firefox)$"
        "focusonactivate, class:^(chromium-browser)$"
        "tile, class:^(starrail\.exe)$"

        # Control-panel workspace utilities (must come before dev workspace ghostty rule)
        "tile, class:^(pavucontrol)$"
        "workspace special:control-panel, class:^(pavucontrol)$"
        "tile, class:^(org\.pulseaudio\.pavucontrol)$"
        "workspace special:control-panel, class:^(org\.pulseaudio\.pavucontrol)$"
        "tile, title:^(nmtui)$"
        "workspace special:control-panel, title:^(nmtui)$"
        "tile, title:^(blueman-manager)$"
        "workspace special:control-panel, title:^(blueman-manager)$"
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
        "opacity 1.0 override 1.0 override 1.0 override, class:^(steam_app_.*)$"
        "opacity 1.0 override 1.0 override 1.0 override, class:^(steam)$"
        "opacity 1.0 override 1.0 override 1.0 override, class:^(io\.github\.htkhiem\.Euphonica)$"
      ];
    };
    extraConfig = ''
      submap = resize
      binde = , right, resizeactive, 100 0
      binde = , left, resizeactive, -100 0
      binde = , down, resizeactive, 0 100
      binde = , up, resizeactive, 0 -100
      bind = , escape, submap, reset
      bind = , return, submap, reset
      submap = reset
    '';
  };
  };
}
