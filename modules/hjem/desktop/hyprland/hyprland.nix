{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
  pinToggle = pkgs.writeScriptBin "hypr-pin-toggle" ''
    #!/usr/bin/env nu
    def main [] {
      let win = (hyprctl activewindow -j | from json)
      if $win.pinned {
        hyprctl dispatch pin
        hyprctl dispatch togglefloating
      } else {
        if not $win.floating {
          hyprctl dispatch togglefloating
        }
        hyprctl dispatch pin
      }
    }
  '';
  hyprFocus = pkgs.writeScriptBin "hypr-focus" ''
    #!/usr/bin/env nu
    def main [direction: string] {
      let layout = (hyprctl activeworkspace -j | from json | get tiledLayout)
      if $layout == "monocle" {
        match $direction {
          "l" | "u" => { ^hyprctl dispatch "hl.dsp.layout('cycleprev')" }
          "r" | "d" => { ^hyprctl dispatch "hl.dsp.layout('cyclenext')" }
        }
      } else {
        ^hyprctl dispatch ("hl.dsp.focus({ direction = '" + $direction + "' })")
      }
    }
  '';
in
{
  users.users.${username}.packages = [
    hyprFocus
    pinToggle
  ];
  # graphical-session.target has RefuseManualStart; this bound target is started from the lua start hook to activate it as a dependency
  systemd.user.targets.hyprland-session = {
    description = "Hyprland session";
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
  };
  hjem.users.${username} = {
    xdg.config.files."hypr/hyprland.lua".source = ./hyprland.lua;
  };
}
