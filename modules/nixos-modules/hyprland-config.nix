{...}: {
  flake.nixosModules.hyprland-config = {
    config,
    lib,
    ...
  }:
    with lib; {
      config = mkIf config.mySystem.features.desktop {
        home-manager.users.${config.mySystem.user.name} = {
          wayland.windowManager.hyprland = {
            enable = true;
            settings = {
              "$fileManager" = "hyprctl dispatch exec '[size 1600 900; move 531 262; float; opacity 1.0 override 1.0 override 1.0 override] ghostty -e superfile'";
              "$terminal" = "ghostty --title=ghostty";
              "$webBrowser" = "helium";
              "$mainMod" = "SUPER";
              "$sysMon" = "hyprctl dispatch exec '[size 1600 900; move 531 262; float; opacity 1.0 override 1.0 override 1.0 override] ghostty --title=btop -e btop'";
              monitor = [
                "HDMI-A-2, 2560x1440@144, 0x0, 1"
                ", preferred, auto, 1"
              ];
              env = [
                "HYPRCURSOR_THEME,phinger-cursors-dark-hyprcursor"
                "HYPRCURSOR_SIZE,32"
                "XCURSOR_THEME,phinger-cursors-dark"
                "XCURSOR_SIZE,32"
                "TERMINAL,ghostty"
                "XDG_TERMINAL_EDITOR,ghostty"
              ];
              source = [
                "~/.config/hypr/noctalia/noctalia-colors.conf"
              ];
              exec-once = [
                "steam"
                "noctalia-shell"
                "$webBrowser"
                "zeditor"
                "euphonica"
                "vesktop"
              ];
              general = {
                gaps_in = 3;
                gaps_out = 6;
                border_size = 3;
                resize_on_border = false;
                allow_tearing = false;
                layout = "dwindle";
              };
              dwindle = {
                pseudotile = true;
                preserve_split = true;
              };
              workspace = [
                "1, defaultName:comms, gapsin:3, gapsout:6, persistent:true"
                "2, defaultName:dev, gapsin:3, gapsout:6, persistent:true"
                "3, defaultName:games, gapsin:0, gapsout:0, rounding:false, persistent:true"
                "4, defaultName:media, gapsin:3, gapsout:6, persistent:true"
                "5, defaultName:web, gapsin:3, gapsout:6, persistent:true"
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
                active_opacity = 0.94;
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
                follow_mouse = "1";
                sensitivity = 0;
              };
              device = {
                "name" = "epic-mouse-v1";
                sensitivity = -0.5;
              };
              animations = {
                enabled = 1;
                animation = [
                  "windows, 1, 3, zoom"
                  "windowsOut, 1, 3, default, popin 10%"
                  "border, 1, 3, default"
                  "fade, 1, 3, default"
                  "workspaces, 1, 3, default"
                  "windowsMove, 1, 3, zoom"
                  "windowsOut, 1, 3, zoom"
                  "fade, 1, 3, default"
                  "workspaces, 1, 3, overshot, slide"
                ];
                bezier = [
                  "zoom, 0.1, 0.9, 0.1, 1.2"
                  "overshot,0.05,0.9,0.1,1.5"
                  "overshot,0.13,0.99,0.29,1.5"
                ];
              };
            };
          };
        };
      };
    };
}
