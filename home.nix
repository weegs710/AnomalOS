{
  lib,
  pkgs,
  config,
  ...
}:

{
  home.username = "weegs";
  home.homeDirectory = "/home/weegs";

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    alejandra
    alarm-clock-applet
    btop-rocm
    cliphist
    dunst
    fastfetch
    fzf
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
    wl-clipboard
    wl-clip-persist
    wlogout
    wlsunset
  ];

  home.file = { };

  home.sessionVariables = {
    EDITOR = "zeditor";
    NIXOS_OZONE_WL = "1";
    TERMINAL = "kitty";
    VISUAL = "zeditor";
    XDG_TERMINAL_EDITOR = "kitty";
  };

  programs.home-manager.enable = true;

  wayland.windowManager.hyprland = {
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
        "swww img ${config.home.homeDirectory}/Pictures/monster.jpg"
        "dunst &"
        "nfa &"
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
        new_status = "slave";
        mfact = 0.60;
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
      workspace = [
        "1, persistent:true"
        "2, persistent:true"
        "3, persistent:true"
        "4, persistent:true"
        "5, persistent:true"
      ];
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
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"
        "$mainMod, minus, togglespecialworkspace, scratchpad"
        "$mainMod SHIFT, minus, movetoworkspacesilent, special:scratchpad"
        "$mainMod, page_down, workspace, e+1"
        "$mainMod, page_up, workspace, e-1"
        ", PRINT, exec, hyprshot -m region --clipboard-only"
        "SHIFT,PRINT, exec, hyprshot -m region -o ~/Pictures"
      ];
      bindel = [
        "control ,right, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        "control ,left , exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        "control ,down, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
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
        "control&alt, B, exec, $webBrowser"
        "control&alt, D, exec, vesktop"
        "control&alt, F, exec, $fileManager"
        "control&alt, R, exec, tmux new -d -s roku_app 'appimage-run ~/AppImages/roku.AppImage'"
        "control&alt, S, exec, steam"
        "control&alt, T, exec, $terminal"
        "control&alt, Y, exec, freetube"
        "control&alt, Z, exec, zeditor"
        "control&alt $mainMod, B, exec, kitty -e bluetui"
        "control&alt $mainMod, L, exec, hyprlock"
        "control&alt $mainMod, N, exec, kitty -e nmtui"
        "control&alt $mainMod, delete, exec, wlogout"
      ];
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };
}
