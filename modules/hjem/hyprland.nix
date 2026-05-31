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
  hjem.users.${username} = {
    xdg.config.files."hypr/hyprland.lua".text = ''
      -- noctalia colors hardcoded until v5 ships noctalia-colors.lua; swap to dofile() then

      local terminal = "ghostty --title=ghostty"
      local mainMod  = "SUPER"

      -- monitors
      -- hl.monitor({ output = "NAME", mode = "WxH@Hz", position = "XxY", scale = "1" })
      hl.monitor({ output = "HDMI-A-2", mode = "2560x1440@144", position = "0x0",  scale = "1" })
      hl.monitor({ output = "",          mode = "preferred",      position = "auto", scale = "auto" })

      -- environment
      -- hl.env("KEY", "value")
      hl.env("HYPRCURSOR_THEME",    "fft-ivalice-hyprcursor")
      hl.env("HYPRCURSOR_SIZE",     "32")
      hl.env("XCURSOR_THEME",       "phinger-cursors-dark")
      hl.env("XCURSOR_SIZE",        "32")
      hl.env("TERMINAL",            "ghostty")
      hl.env("XDG_TERMINAL_EDITOR", "ghostty")

      -- autostart
      -- hl.on("hyprland.start", function() hl.exec_cmd("cmd") end)
      hl.on("hyprland.start", function()
          hl.exec_cmd("dbus-update-activation-environment --systemd --all")
          hl.exec_cmd("noctalia-shell")
          hl.exec_cmd("kdeconnect-indicator")
      end)

      -- colors
      -- local color = "rgb(rrggbb)"
      local primary   = "rgb(37f499)"
      local surface   = "rgb(212337)"
      local secondary = "rgb(04d1f9)"
      local error_col = "rgb(f16c75)"

      -- config
      -- hl.config({ section = { key = value } })
      hl.config({
          general = {
              gaps_in          = 5,
              gaps_out         = 10,
              border_size      = 1,
              resize_on_border = false,
              allow_tearing    = false,
              layout           = "dwindle",
              col = {
                  active_border   = primary,
                  inactive_border = surface,
              },
          },

          group = {
              col = {
                  border_active          = secondary,
                  border_inactive        = surface,
                  border_locked_active   = error_col,
                  border_locked_inactive = surface,
              },
              groupbar = {
                  col = {
                      active          = secondary,
                      inactive        = surface,
                      locked_active   = error_col,
                      locked_inactive = surface,
                  },
              },
          },

          dwindle = {
              preserve_split = true,
          },

          scrolling = {
              column_width             = 0.9,
              focus_fit_method         = 0,
              fullscreen_on_one_column = true,
          },

          master = {
              always_keep_position = false,
              new_status           = "master",
              orientation          = "top",
              mfact                = 0.75,
              new_on_top           = true,
          },

          misc = {
              force_default_wallpaper = -1,
              disable_hyprland_logo   = false,
              vrr                     = 1,
          },

          decoration = {
              rounding         = 6,
              active_opacity   = 1.0,
              inactive_opacity = 1.0,
              shadow = {
                  enabled      = true,
                  range        = 8,
                  render_power = 4,
              },
              blur = {
                  enabled           = false,
                  size              = 2,
                  passes            = 1,
                  new_optimizations = true,
                  ignore_opacity    = false,
                  vibrancy          = 0.35,
              },
          },

          input = {
              kb_layout    = "us",
              follow_mouse = 1,
              sensitivity  = 0,
              accel_profile = "flat",
          },
      })

      hl.device({ name = "epic-mouse-v1", sensitivity = 1.0 })

      -- animations
      -- hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "curve", style = "slide" })
      -- overshot uses second (winning) hyprlang declaration's values
      hl.curve("zoom",     { type = "bezier", points = { {0.1, 0.9},   {0.1, 1.2}  } })
      hl.curve("overshot", { type = "bezier", points = { {0.13, 0.99}, {0.29, 1.5} } })

      hl.animation({ leaf = "windows",     enabled = true, speed = 3, bezier = "zoom" })
      hl.animation({ leaf = "windowsOut",  enabled = true, speed = 3, bezier = "zoom" })
      hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "zoom" })
      hl.animation({ leaf = "border",      enabled = true, speed = 3, bezier = "default" })
      hl.animation({ leaf = "fade",        enabled = true, speed = 3, bezier = "default" })
      hl.animation({ leaf = "workspaces",  enabled = true, speed = 3, bezier = "overshot", style = "slide" })
      hl.animation({ leaf = "layers",      enabled = true, speed = 3, bezier = "zoom",     style = "fade" })

      -- workspaces
      -- hl.workspace_rule({ workspace = "N", default_name = "name", layout = "dwindle", persistent = true })
      hl.workspace_rule({ workspace = "1",                     default_name = "comms", gaps_in = 5, gaps_out = 10, persistent = true })
      hl.workspace_rule({ workspace = "2",                     default_name = "dev",   gaps_in = 5, gaps_out = 10, persistent = true, layout = "scrolling" })
      hl.workspace_rule({ workspace = "3",                     default_name = "web",   gaps_in = 5, gaps_out = 10, persistent = true, layout = "master" })
      hl.workspace_rule({ workspace = "4",                     default_name = "games", gaps_in = 0, gaps_out = 0,  persistent = true, layout = "monocle", no_rounding = true })
      hl.workspace_rule({ workspace = "5",                     default_name = "media", gaps_in = 5, gaps_out = 10, persistent = true, layout = "monocle" })
      hl.workspace_rule({ workspace = "special:control-panel",                         gaps_in = 5, gaps_out = 10, layout = "scrolling" })

      -- window rules
      -- hl.window_rule({ match = { class = "^class$" }, float = true, workspace = "N" })

      -- dialogs
      hl.window_rule({ match = { float = true }, opacity = "1.0 override 1.0 override 1.0 override" })
      hl.window_rule({ match = { title = "^(Open)(.*)$" },          float = true })
      hl.window_rule({ match = { title = "^(Save)(.*)$" },          float = true })
      hl.window_rule({ match = { title = "^(Save As)(.*)$" },       float = true })
      hl.window_rule({ match = { title = "^(Choose)(.*)$" },        float = true })
      hl.window_rule({ match = { title = "^(Select)(.*)$" },        float = true })
      hl.window_rule({ match = { title = "^(Preferences)(.*)$" },   float = true })
      hl.window_rule({ match = { title = "^(Settings)(.*)$" },      float = true })
      hl.window_rule({ match = { title = "^(Properties)(.*)$" },    float = true })
      hl.window_rule({ match = { title = "^(Create Folder)(.*)$" }, float = true })
      hl.window_rule({ match = { title = "^(Rename)(.*)$" },        float = true })
      hl.window_rule({ match = { title = "^(Delete)(.*)$" },        float = true })
      hl.window_rule({ match = { title = "^(.*[Dd]ialog.*)$" },     float = true })
      hl.window_rule({ match = { title = "^(.*[Pp]opup.*)$" },      float = true })

      -- auth
      hl.window_rule({ match = { class = "^(gcr-prompter)$" }, stay_focused = true, focus_on_activate = true })

      -- file chooser
      hl.window_rule({ match = { title = "^(termfilechooser)$" }, float = true, size = {1600, 900}, move = {531, 262}, opacity = "1.0 override 1.0 override 1.0 override" })

      -- screenshots
      hl.window_rule({ match = { title = "^(name-shot|name-clip)$" }, float = true, size = {360, 130}, center = true, stay_focused = true, focus_on_activate = true })

      -- picture in picture
      hl.window_rule({ match = { initial_title = "Picture in picture" }, float = true, pin = true, size = {512, 288}, move = {2034, 62} })

      -- comms
      hl.window_rule({ match = { title = "^(concord)$" },  workspace = "1" })
      hl.window_rule({ match = { title = "^(weechat)$" },  workspace = "1" })
      hl.window_rule({ match = { title = "^(profanity)$" },  workspace = "1" })

      -- dev
      hl.window_rule({ match = { title = "^(ghostty)$" },  workspace = "2" })

      hl.window_rule({ match = { class = "^(emacs)$" },    workspace = "2" })

      -- browser
      hl.window_rule({ match = { class = "^(zen)$", initial_title = "^(Zen Browser)$" }, workspace = "3" })
      hl.window_rule({ match = { class = "^(zen)$" }, focus_on_activate = true })
      hl.window_rule({ match = { class = "^(zen)$" }, opacity = "1.0 override 1.0 override 1.0 override" })

      -- gaming
      hl.window_rule({ match = { class = "^(heroic)$" },       workspace = "4" })
      hl.window_rule({ match = { class = "^(steam)$" },        workspace = "4", opacity = "1.0 override 1.0 override 1.0 override" })
      hl.window_rule({ match = { class = "^(steam_app_.*)$" }, workspace = "4", opacity = "1.0 override 1.0 override 1.0 override", focus_on_activate = true })
      hl.window_rule({ match = { class = "^(crawl-tiles)$" },  workspace = "4" })
      hl.window_rule({ match = { class = "^(gamescope)$" },    workspace = "4", fullscreen = true, opacity = "1.0 override 1.0 override 1.0 override", focus_on_activate = true })

      -- media
      hl.window_rule({ match = { class = "^(zen-jellyfin)$" },           workspace = "5" })
      hl.window_rule({ match = { class = "^(zen)$", title = ".*Jellyfin.*" }, workspace = "5" })
      hl.window_rule({ match = { class = "^(mpv)$" },                    workspace = "5" })
      hl.window_rule({ match = { class = "^(gimp)$" },                   workspace = "5" })
      hl.window_rule({ match = { class = "^(org%.inkscape%.Inkscape)$" }, workspace = "5" })
      hl.window_rule({ match = { title = "^(rmpc)$" },                   workspace = "5" })

      -- stash
      hl.window_rule({ match = { class = "^(pavucontrol)$" },                      tile = true, workspace = "special:stash" })
      hl.window_rule({ match = { class = "^(org%.pulseaudio%.pavucontrol)$" },      tile = true, workspace = "special:stash" })
      hl.window_rule({ match = { title = "^(pulsemixer)$" },                        tile = true, workspace = "special:stash" })
      hl.window_rule({ match = { title = "^(nmtui)$" },                             tile = true, workspace = "special:stash" })
      hl.window_rule({ match = { title = "^(blueman-manager)$" },                   tile = true, workspace = "special:stash" })
      hl.window_rule({ match = { class = "^(io%.github%.ilya_zlobintsev%.LACT)$" }, float = true, workspace = "special:stash" })
      hl.window_rule({ match = { class = "^(cliphist)$" },                           float = true, workspace = "special:stash" })
      hl.window_rule({ match = { class = "^(piper)$" },                              float = true, workspace = "special:stash" })
      hl.window_rule({ match = { title = "^(btop)$" },                               float = true, workspace = "special:stash" })

      -- dev workspace opacity (pinned windows re-trigger dynamically)
      hl.window_rule({ match = { workspace = "2", title = "negative:^(rmpc)$" }, opacity = "0.94 override 0.90 override" })

      -- keybinds
      -- hl.bind("SUPER + key", hl.dsp.dispatcher(), { repeating = true })

      -- window management
      hl.bind(mainMod .. " + escape",    hl.dsp.window.close())
      hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen())
      hl.bind(mainMod .. " + G",         hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mainMod .. " + P",         hl.dsp.window.pseudo())
      hl.bind(mainMod .. " + O",         hl.dsp.layout("togglesplit"))
      hl.bind(mainMod .. " + backslash", hl.dsp.exec_cmd("hypr-pin-toggle"))

      -- launch
      hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
      hl.bind(mainMod .. " + Space",  hl.dsp.exec_cmd("ghostty -e yazi", { float = true, size = {1600, 900}, move = {531, 262} }))

      -- submap entry
      hl.bind(mainMod .. " + Backspace", hl.dsp.submap("resize"))

      -- workspace focus
      hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }))
      hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }))
      hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }))
      hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }))
      hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }))

      -- window to workspace
      hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
      hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
      hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
      hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
      hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))

      -- workspace scroll
      hl.bind(mainMod .. " + page_down",  hl.dsp.focus({ workspace = "e+1" }))
      hl.bind(mainMod .. " + page_up",    hl.dsp.focus({ workspace = "e-1" }))
      hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e-1" }))
      hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e+1" }))

      -- special workspaces
      hl.bind(mainMod .. " + grave",         hl.dsp.workspace.toggle_special("stash"))
      hl.bind(mainMod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:stash" }))

      -- audio
      hl.bind(mainMod .. " + pause", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
      hl.bind("CTRL + pause",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
      hl.bind(mainMod .. " + home",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
      hl.bind(mainMod .. " + end",   hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })

      -- focus movement (hypr-focus cycles layout in monocle, directional focus otherwise)
      hl.bind(mainMod .. " + left",  hl.dsp.exec_cmd("hypr-focus l"), { repeating = true })
      hl.bind(mainMod .. " + right", hl.dsp.exec_cmd("hypr-focus r"), { repeating = true })
      hl.bind(mainMod .. " + up",    hl.dsp.exec_cmd("hypr-focus u"), { repeating = true })
      hl.bind(mainMod .. " + down",  hl.dsp.exec_cmd("hypr-focus d"), { repeating = true })

      -- window movement
      hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "l" }), { repeating = true })
      hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }), { repeating = true })
      hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "u" }), { repeating = true })
      hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "d" }), { repeating = true })

      -- mouse window ops
      hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
      hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

      -- system / UI
      hl.bind("SUPER + Super_L",     hl.dsp.exec_cmd("wlr-which-key"),                                { release = true })
      hl.bind("Print",               hl.dsp.exec_cmd("wlr-which-key capture"))
      hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("wlr-which-key power"))
      hl.bind("CTRL + ALT + L",      hl.dsp.exec_cmd("noctalia-shell ipc call lockScreen lock"),      { release = true })
      hl.bind(mainMod .. " + tab",   hl.dsp.exec_cmd("noctalia-shell ipc call controlCenter toggle"), { release = true })

      -- resize submap
      hl.define_submap("resize", function()
          hl.bind("right",  hl.dsp.window.resize({ x = 100,  y = 0    }), { repeating = true })
          hl.bind("left",   hl.dsp.window.resize({ x = -100, y = 0    }), { repeating = true })
          hl.bind("down",   hl.dsp.window.resize({ x = 0,    y = 100  }), { repeating = true })
          hl.bind("up",     hl.dsp.window.resize({ x = 0,    y = -100 }), { repeating = true })
          hl.bind("escape", hl.dsp.submap("reset"))
          hl.bind("return", hl.dsp.submap("reset"))
      end)
    '';
  };
}
