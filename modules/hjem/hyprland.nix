{
  flake.nixosModules.hyprland = {
    config,
    lib,
    ...
  }: let
    username = config.mySystem.user.name;
  in {
    config = lib.mkIf config.mySystem.features.desktop {
        hjem.users.${username} = {
          xdg.config.files."hypr/hyprland.conf".text = ''
            # Variables
            $fileManager = hyprctl dispatch exec '[size 1600 900; move 531 262; float; opacity 1.0 override 1.0 override 1.0 override] ghostty -e superfile'
            $terminal = ghostty --title=ghostty
            $editor = ghostty --title=flow -e fish -c "cd ~/dotfiles && exec flow"
            $webBrowser = helium
            $mainMod = SUPER
            $sysMon = hyprctl dispatch exec '[size 1600 900; move 531 262; float; opacity 1.0 override 1.0 override 1.0 override] ghostty --title=btop -e btop'
            $music = hyprctl dispatch exec '[size 1600 900; move 531 262; float; opacity 1.0 override 1.0 override 1.0 override] euphonica'


            # Monitors
            monitor = HDMI-A-2, 2560x1440@144, 0x0, 1
            monitor = , preferred, auto, 1

            # Environment
            env = HYPRCURSOR_THEME,phinger-cursors-dark-hyprcursor
            env = HYPRCURSOR_SIZE,32
            env = XCURSOR_THEME,phinger-cursors-dark
            env = XCURSOR_SIZE,32
            env = TERMINAL,ghostty
            env = XDG_TERMINAL_EDITOR,ghostty

            # Source
            source = ~/.config/hypr/noctalia/noctalia-colors.conf

            # Autostart
            exec-once = dbus-update-activation-environment --systemd --all
            exec-once = noctalia-shell

            # General
            general {
                gaps_in = 3
                gaps_out = 6
                border_size = 3
                resize_on_border = false
                allow_tearing = false
                layout = dwindle
            }

            # Dwindle Layout
            dwindle {
                pseudotile = true
                preserve_split = true
            }

            # Workspaces
            workspace = 1, defaultName:comms, gapsin:3, gapsout:6, persistent:true
            workspace = 2, defaultName:dev, gapsin:3, gapsout:6, persistent:true
            workspace = 3, defaultName:games, gapsin:0, gapsout:0, rounding:false, persistent:true
            workspace = 4, defaultName:media, gapsin:3, gapsout:6, persistent:true
            workspace = 5, defaultName:web, gapsin:3, gapsout:6, persistent:true
            workspace = special:control-panel, gapsin:2, gapsout:5

            # Master Layout
            master {
                always_keep_position = false
                new_status = master
                orientation = top
                mfact = 0.60
                new_on_top = true
            }

            # Misc
            misc {
                force_default_wallpaper = -1
                disable_hyprland_logo = false
                vrr = 1
            }

            # Decoration
            decoration {
                rounding = 10
                active_opacity = 0.94
                inactive_opacity = 0.90
                shadow {
                    enabled = true
                    range = 8
                    render_power = 4
                }
                blur {
                    enabled = false
                    size = 2
                    passes = 1
                    new_optimizations = true
                    ignore_opacity = false
                    vibrancy = 0.35
                }
            }

            # Input
            input {
                kb_layout = us
                follow_mouse = 1
                sensitivity = 0
            }

            # Device
            device {
                name = epic-mouse-v1
                sensitivity = -0.5
            }

            # Animations
            animations {
                enabled = 1
                bezier = zoom, 0.1, 0.9, 0.1, 1.2
                bezier = overshot, 0.05, 0.9, 0.1, 1.5
                bezier = overshot, 0.13, 0.99, 0.29, 1.5
                animation = windows, 1, 3, zoom
                animation = windowsOut, 1, 3, default, popin 10%
                animation = border, 1, 3, default
                animation = fade, 1, 3, default
                animation = workspaces, 1, 3, default
                animation = windowsMove, 1, 3, zoom
                animation = windowsOut, 1, 3, zoom
                animation = fade, 1, 3, default
                animation = workspaces, 1, 3, overshot, slide
            }

            # Keybinds
            bind = $mainMod, escape, killactive
            bind = $mainMod, F, fullscreen
            bind = $mainMod, G, togglefloating
            bind = $mainMod, P, pseudo,
            bind = $mainMod, O, togglesplit,
            bind = $mainMod, F1, exec, ghostty --title=endcord --font-size=11 -e endcord
            bind = $mainMod, F2, exec, $editor
            bind = $mainMod, F3, exec, steam
            bind = $mainMod, F4, exec, $music
            bind = $mainMod SHIFT, F4, exec, flatpak run com.stremio.Stremio
            bind = $mainMod, F5, exec, $webBrowser
            bind = $mainMod, F6, exec, $sysMon
            bind = $mainMod, Return, exec, $terminal
            bind = $mainMod, Space, exec, $fileManager
            bind = $mainMod, Backspace, submap, resize
            bind = $mainMod, 1, workspace, 1
            bind = $mainMod, 2, workspace, 2
            bind = $mainMod, 3, workspace, 3
            bind = $mainMod, 4, workspace, 4
            bind = $mainMod, 5, workspace, 5
            bind = $mainMod SHIFT, 1, movetoworkspace, 1
            bind = $mainMod SHIFT, 2, movetoworkspace, 2
            bind = $mainMod SHIFT, 3, movetoworkspace, 3
            bind = $mainMod SHIFT, 4, movetoworkspace, 4
            bind = $mainMod SHIFT, 5, movetoworkspace, 5
            bind = $mainMod, page_down, workspace, e+1
            bind = $mainMod, page_up, workspace, e-1
            bind = $mainMod, mouse_down, workspace, e-1
            bind = $mainMod, mouse_up, workspace, e+1
            bind = $mainMod, grave, togglespecialworkspace, stash
            bind = $mainMod SHIFT, grave, movetoworkspace, special:stash
            bind = $mainMod, pause, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
            bind = , PRINT, exec, hyprshot -m region --clipboard-only
            bind = SHIFT, PRINT, exec, hyprshot -m region -o ~/Pictures
            bind = CTRL, PRINT, exec, hyprshot -m window --clipboard-only
            bindel = $mainMod, home, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
            bindel = $mainMod, end, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
            binde = $mainMod, left, movefocus, l
            binde = $mainMod, right, movefocus, r
            binde = $mainMod, up, movefocus, u
            binde = $mainMod, down, movefocus, d
            binde = $mainMod SHIFT, left, movewindow, l
            binde = $mainMod SHIFT, right, movewindow, r
            binde = $mainMod SHIFT, up, movewindow, u
            binde = $mainMod SHIFT, down, movewindow, d
            bindr = SUPER, Super_L, exec, noctalia-shell ipc call launcher toggle
            bindr = CTRL_ALT, L, exec, noctalia-shell ipc call lockScreen lock
            bindr = $mainMod, tab, exec, noctalia-shell ipc call controlCenter toggle
            bindm = $mainMod, mouse:272, movewindow
            bindm = $mainMod, mouse:273, resizewindow

            # Submaps
            submap = resize
            binde = , right, resizeactive, 100 0
            binde = , left, resizeactive, -100 0
            binde = , down, resizeactive, 0 100
            binde = , up, resizeactive, 0 -100
            bind = , escape, submap, reset
            bind = , return, submap, reset
            submap = reset

            # Window Rules
            windowrule = opacity 1.0 override 1.0 override 1.0 override, match:float yes
            windowrule = float on, match:title ^(Open)(.*)$
            windowrule = float on, match:title ^(Save)(.*)$
            windowrule = float on, match:title ^(Save As)(.*)$
            windowrule = float on, match:title ^(Choose)(.*)$
            windowrule = float on, match:title ^(Select)(.*)$
            windowrule = float on, match:title ^(Preferences)(.*)$
            windowrule = float on, match:title ^(Settings)(.*)$
            windowrule = float on, match:title ^(Properties)(.*)$
            windowrule = float on, match:title ^(Create Folder)(.*)$
            windowrule = float on, match:title ^(Rename)(.*)$
            windowrule = float on, match:title ^(Delete)(.*)$
            windowrule = float on, match:title ^(termfilechooser)$
            windowrule = size 1600 900, match:title ^(termfilechooser)$
            windowrule = move 531 262, match:title ^(termfilechooser)$
            windowrule = opacity 1.0 override 1.0 override 1.0 override, match:title ^(termfilechooser)$
            windowrule = float on, match:title ^(.*[Dd]ialog.*)$
            windowrule = float on, match:title ^(.*[Pp]opup.*)$
            windowrule = workspace 1, match:class ^(vesktop)$
            windowrule = workspace 1, match:class ^(im.dino.Dino)$
            windowrule = workspace 1, match:title ^(endcord)$
            windowrule = workspace 2, match:class ^(dev\.zed\.Zed)$
            windowrule = workspace 2, match:class ^(Zed)$
            windowrule = workspace 2, match:title ^(ghostty)$
            windowrule = workspace 3, match:class ^(steam)$
            windowrule = workspace 3, match:class ^(steam_app_.*)$
            windowrule = fullscreen on, match:class ^(steam_app_3564740)$
            windowrule = suppress_event fullscreen, match:class ^(steam_app_3564740)$
            windowrule = workspace 4, match:class ^(chrome-fanduelsportsnetwork\.com__teams_nhl-blue-jackets-Default)$
            windowrule = workspace 5, match:class ^(helium)$, match:initial_title ^(New Tab - Helium)$
            windowrule = focus_on_activate on, match:class ^(helium)$
            windowrule = tile on, match:class ^(pavucontrol)$
            windowrule = workspace special:stash, match:class ^(pavucontrol)$
            windowrule = tile on, match:class ^(org\.pulseaudio\.pavucontrol)$
            windowrule = workspace special:stash, match:class ^(org\.pulseaudio\.pavucontrol)$
            windowrule = tile on, match:title ^(nmtui)$
            windowrule = workspace special:stash, match:title ^(nmtui)$
            windowrule = tile on, match:title ^(blueman-manager)$
            windowrule = workspace special:stash, match:title ^(blueman-manager)$
            windowrule = float on, match:class ^(io\.github\.ilya_zlobintsev\.LACT)$
            windowrule = workspace special:stash, match:class ^(io\.github\.ilya_zlobintsev\.LACT)$
            windowrule = float on, match:class ^(cliphist)$
            windowrule = workspace special:stash, match:class ^(cliphist)$
            windowrule = float on, match:class ^(piper)$
            windowrule = workspace special:stash, match:class ^(piper)$
            windowrule = float on, match:class ^(com\.github\.jkotra\.eovpn)$
            windowrule = workspace special:stash, match:class ^(com\.github\.jkotra\.eovpn)$
            windowrule = float on, match:title ^(btop)$
            windowrule = workspace special:stash, match:title ^(btop)$
            windowrule = workspace 2, match:title ^(flow)$
            windowrule = tile on, match:title ^(pulsemixer)$
            windowrule = workspace special:stash, match:title ^(pulsemixer)$
            windowrule = opacity 1.0 override 1.0 override 1.0 override, match:class ^(vesktop)$
            windowrule = opacity 1.0 override 1.0 override 1.0 override, match:class ^(helium)$
            windowrule = opacity 1.0 override 1.0 override 1.0 override, match:class ^(steam_app_.*)$
            windowrule = opacity 1.0 override 1.0 override 1.0 override, match:class ^(steam)$
            windowrule = float on, match:initial_title Picture in picture
            windowrule = pin on, match:initial_title Picture in picture
            windowrule = size 512 288, match:initial_title Picture in picture
            windowrule = move 2034 62, match:initial_title Picture in picture
            windowrule = float on, match:class ^(com\.stremio\.stremio)$
            windowrule = pin on, match:class ^(com\.stremio\.stremio)$
            windowrule = size 1170 666, match:class ^(com\.stremio\.stremio)$
            windowrule = move 1375 60, match:class ^(com\.stremio\.stremio)$
            windowrule = match:class ^(gcr-prompter)$, stay_focused on
            windowrule = match:class ^(gcr-prompter)$, focus_on_activate on
          '';
        };
      };
    };
}
