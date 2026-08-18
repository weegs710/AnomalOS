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
      } else if $layout == "scrolling" {
        # plain movefocus is geometric and can't reach off-viewport columns; the scrolling layoutmsg is tape-aware
        ^hyprctl dispatch ("hl.dsp.layout('focus " + $direction + "')")
      } else {
        ^hyprctl dispatch ("hl.dsp.focus({ direction = '" + $direction + "' })")
      }
    }
  '';
  splitToggle = pkgs.writeScriptBin "hypr-split-toggle" ''
    #!/usr/bin/env nu
    # toggle the focused scrolling window between stacked (one column) and stripped (even side-by-side columns)
    def scroll-split-toggle [] {
      let active = (hyprctl activewindow -j | from json)
      if ($active | is-empty) {
        return
      }

      let clients  = (hyprctl clients -j | from json)
      let wsid     = $active.workspace.id
      let ax       = ($active.at | get 0)
      let peers    = ($clients | where {|w| $w.workspace.id == $wsid and (not $w.floating) and $w.mapped })
      # a column is a vertical stack at one horizontal offset, so shared x means shared column
      let colmates = ($peers | where {|w| (($w.at | get 0) - $ax | math abs) <= 20 })

      if ($colmates | length) > 1 {
        # stacked -> stripped: pop the partner out, then even the columns side by side
        ^hyprctl dispatch "hl.dsp.layout('expel')"
        ^hyprctl dispatch "hl.dsp.layout('fit all')"
      } else {
        let cols     = ($peers | each {|w| $w.at | get 0 } | uniq | sort)
        let hasRight = ($cols | any {|x| $x > ($ax + 20) })
        let hasLeft  = ($cols | any {|x| $x < ($ax - 20) })
        # stripped/default -> stacked: merge a neighbor in, then fill the column
        if $hasRight {
          ^hyprctl dispatch "hl.dsp.layout('consume')"
          ^hyprctl dispatch "hl.dsp.layout('fit active')"
        } else if $hasLeft {
          ^hyprctl dispatch "hl.dsp.layout('consume_or_expel prev')"
          ^hyprctl dispatch "hl.dsp.layout('fit active')"
        }
      }
    }

    def main [] {
      let layout = (hyprctl activeworkspace -j | from json | get tiledLayout)
      match $layout {
        "monocle" => null
        "scrolling" => (scroll-split-toggle)
        _ => (^hyprctl dispatch "hl.dsp.layout('togglesplit')")
      }
    }
  '';
in
{
  users.users.${username}.packages = [
    hyprFocus
    pinToggle
    splitToggle
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
