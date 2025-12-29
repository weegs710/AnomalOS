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
  };
}
