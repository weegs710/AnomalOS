{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.desktop {
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$terminal" = "ghostty";
      "$fileManager" = "nemo";
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
          "workspaces,1,4,overshot,slide"
        ];
        bezier = [
          "myBezier, 0.05, 0.9, 0.1, 1.05"
          "overshot,0.05,0.9,0.1,1.1"
          "overshot,0.13,0.99,0.29,1.1"
        ];
      };
    };
  };
  };
}
