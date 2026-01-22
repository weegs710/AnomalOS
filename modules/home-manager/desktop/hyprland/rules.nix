{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.desktop {
    wayland.windowManager.hyprland.settings = {
      windowrule = [
        # Global opacity override for all floating windows
        "opacity 1.0 override 1.0 override 1.0 override, match:float yes"

        # Float common dialog windows (let them position naturally)
        "float on, match:title ^(Open)(.*)$"
        "float on, match:title ^(Save)(.*)$"
        "float on, match:title ^(Save As)(.*)$"
        "float on, match:title ^(Choose)(.*)$"
        "float on, match:title ^(Select)(.*)$"

        # Common dialog patterns
        "float on, match:title ^(Preferences)(.*)$"
        "float on, match:title ^(Settings)(.*)$"
        "float on, match:title ^(Properties)(.*)$"

        # File manager dialogs
        "float on, match:title ^(Create Folder)(.*)$"
        "float on, match:title ^(Rename)(.*)$"
        "float on, match:title ^(Delete)(.*)$"

        # File managers
        "float on, match:class ^(nemo)$"

        # Terminal file chooser (xdg-desktop-portal-termfilechooser)
        "float on, match:title ^(termfilechooser)$"
        "size 1600 900, match:title ^(termfilechooser)$"
        "move 531 262, match:title ^(termfilechooser)$"
        "opacity 1.0 override 1.0 override 1.0 override, match:title ^(termfilechooser)$"

        # Browser popups
        "float on, match:title ^(Picture-in-Picture)(.*)$"
        "pin on, match:title ^(Picture-in-Picture)(.*)$"

        # Generic popup patterns (catch-all)
        "float on, match:title ^(.*[Dd]ialog.*)$"
        "float on, match:title ^(.*[Pp]opup.*)$"

        # Workspace: 1 (comms)
        "workspace 1, match:class ^(vesktop)$"
        "workspace 1, match:class ^(discord)$"

        # Workspace: 2 (dev)
        "workspace 2, match:class ^(dev\.zed\.Zed)$"
        "workspace 2, match:class ^(Zed)$"
        "workspace 2, match:title ^(ghostty)$"

        # Workspace: 3 (games)
        "workspace 3, match:class ^(steam)$"
        "workspace 3, match:class ^(steam_app_.*)$"

        # Where Winds Meet - force fullscreen and prevent the game from toggling fullscreen itself.
        "fullscreen on, match:class ^(steam_app_3564740)$"
        "suppress_event fullscreen, match:class ^(steam_app_3564740)$"

        # Workspace: 4 (media)
        "workspace 4, match:class ^(io\.github\.htkhiem\.Euphonica)$"
        # "workspace 4, match:class ^(org\.nickvision\.cavalier)$"
        # "fullscreen on, match:class ^(org\.nickvision\.cavalier)$"
        "workspace 4, match:class ^(com\.stremio\.stremio)$"
        "workspace 4, match:class ^(chrome-fanduelsportsnetwork\.com__teams_nhl-blue-jackets-Default)$"

        # Workspace: 5 (web)
        "workspace 5, match:class ^(zen)$"
        "focus_on_activate on, match:class ^(zen)$"

        # Stash workspace utilities
        "tile on, match:class ^(pavucontrol)$"
        "workspace special:stash, match:class ^(pavucontrol)$"
        "tile on, match:class ^(org\.pulseaudio\.pavucontrol)$"
        "workspace special:stash, match:class ^(org\.pulseaudio\.pavucontrol)$"
        "tile on, match:title ^(nmtui)$"
        "workspace special:stash, match:title ^(nmtui)$"
        "tile on, match:title ^(blueman-manager)$"
        "workspace special:stash, match:title ^(blueman-manager)$"
        "float on, match:class ^(qalculate-gtk)$"
        "workspace special:stash, match:class ^(qalculate-gtk)$"
        "float on, match:class ^(io\.missioncenter\.MissionCenter)$"
        "workspace special:stash, match:class ^(io\.missioncenter\.MissionCenter)$"
        "float on, match:class ^(io\.github\.ilya_zlobintsev\.LACT)$"
        "workspace special:stash, match:class ^(io\.github\.ilya_zlobintsev\.LACT)$"
        "float on, match:class ^(cliphist)$"
        "workspace special:stash, match:class ^(cliphist)$"
        "float on, match:class ^(piper)$"
        "workspace special:stash, match:class ^(piper)$"
        "float on, match:class ^(com\.github\.jkotra\.eovpn)$"
        "workspace special:stash, match:class ^(com\.github\.jkotra\.eovpn)$"

        # Opacity overrides
        "opacity 1.0 override 1.0 override 1.0 override, match:class ^(vesktop)$"
        "opacity 1.0 override 1.0 override 1.0 override, match:class ^(com\.stremio\.stremio)$"
        "opacity 1.0 override 1.0 override 1.0 override, match:class ^(zen)$"
        "opacity 1.0 override 1.0 override 1.0 override, match:class ^(steam_app_.*)$"
        "opacity 1.0 override 1.0 override 1.0 override, match:class ^(steam)$"
        "opacity 1.0 override 1.0 override 1.0 override, match:class ^(io\.github\.htkhiem\.Euphonica)$"
        "opacity 1.0 override 1.0 override 1.0 override, match:class ^(nemo)$"
      ];
    };
  };
}
