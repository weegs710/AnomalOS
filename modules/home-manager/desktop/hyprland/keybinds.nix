{
  lib,
  osConfig,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.desktop {
    wayland.windowManager.hyprland.settings = {
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
        "$mainMod, F5, exec, $webBrowser"
        "$mainMod, F6, exec, $sysMon"
        "$mainMod, Return, exec, $terminal"
        "$mainMod, Space, exec, $fileManager"
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
        "$mainMod, grave, togglespecialworkspace, stash"
        "$mainMod SHIFT, grave, movetoworkspace, special:stash"
        "$mainMod, pause, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", PRINT, exec, hyprshot -m region --clipboard-only"
        "SHIFT, PRINT, exec, hyprshot -m region -o ~/Pictures"
        "CTRL, PRINT, exec, hyprshot -m window --clipboard-only"
      ];
      bindel = [
        "$mainMod, home, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        "$mainMod, end, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
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
        "SUPER, Super_L, exec, noctalia-shell ipc call launcher toggle"
        "CTRL_ALT, L, exec, noctalia-shell ipc call lockScreen lock"
        "$mainMod, tab, exec, noctalia-shell ipc call controlCenter toggle"
      ];
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };

    wayland.windowManager.hyprland.extraConfig = ''
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
}
