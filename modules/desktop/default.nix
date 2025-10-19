# Desktop Environment Module
#
# Configures a complete Wayland desktop environment when mySystem.features.desktop = true
#
# Components:
#   - hyprland.nix: Hyprland compositor configuration (Waybar, keybindings, window rules)
#   - stylix.nix: System theming and color schemes
#   - media.nix: Media player configurations
#
# Services Enabled:
#   - SDDM display manager (Wayland mode)
#   - PipeWire audio system (ALSA, PulseAudio, JACK compatibility)
#   - XDG desktop portals for app integration
#   - Device management (upower, ratbagd, devmon)
#
# Key Features:
#   - Hyprland tiling Wayland compositor
#   - Complete audio stack with PipeWire
#   - File manager (Yazi terminal-based, Thunar GUI fallback)
#   - Desktop applications (mpv, transmission, vesktop, etc.)
#   - Terminal utilities (kitty, rofi, dunst)
#   - X11 compatibility libraries for legacy apps
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [
    ./hyprland.nix
    ./stylix.nix
    ./media.nix
  ];

  config = mkIf config.mySystem.features.desktop {
    # Basic desktop services
    services = {
      displayManager = {
        autoLogin.enable = false;
        defaultSession = "hyprland";
        sddm = {
          enable = true;
          wayland.enable = true;
        };
      };

      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = config.services.pipewire.enable;
      };

      upower.enable = true;
      ratbagd.enable = true;
      devmon.enable = true;
      locate.enable = true;
    };

    # XDG portal setup
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };

    programs = {
      file-roller.enable = true;
      thunar.enable = true;
      udevil.enable = true;
    };

    # Desktop applications and utilities
    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      # Desktop applications
      # mpv - using VLC instead
      pavucontrol
      qalculate-gtk
      qview
      transmission_4-gtk
      unzipNLS
      vlc
      # vesktop - managed by Home Manager for Stylix theming
      zathura

      # Desktop utilities
      alarm-clock-applet
      bluetui
      fastfetch
      gparted
      piper

      # System libraries and support
      adwaita-icon-theme
      dbus
      dbus-broker
      kdePackages.kwallet-pam
      libGL
      libnotify
      libportal
      lm_sensors
      mesa
      wireplumber
      xdg-dbus-proxy
      xfce.thunar-volman

      # Terminal and system utilities
      cliphist
      dunst
      kitty
      pamixer
      rofi
      ueberzugpp

      # X11 compatibility libraries
      xorg.libX11
      xorg.libXcursor
      xorg.libXi
      xorg.libXinerama
      xorg.libXrandr
      xorg.libXxf86vm
    ];

    # Desktop utility aliases
    environment.shellAliases = {
      gparted = "sudo WAYLAND_DISPLAY=$WAYLAND_DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR gparted";
    };

    # Home Manager configuration for desktop
    home-manager.users.${config.mySystem.user.name} = {
      # Enable Yazi file manager with Stylix theming
      programs.yazi = {
        enable = true;
        enableFishIntegration = true;
        # Keep existing custom keymaps and settings
        keymap = builtins.fromTOML (builtins.readFile ./yazi/keymap.toml);
        settings = builtins.fromTOML (builtins.readFile ./yazi/yazi.toml);
        # Override theme to use base00 as background
        theme = {
          mgr = {
            bg = lib.mkForce "#${config.lib.stylix.colors.base00}";
          };
          status = {
            separator_open = lib.mkForce "";
            separator_close = lib.mkForce "";
            separator_style = lib.mkForce { fg = "#${config.lib.stylix.colors.base00}"; bg = "#${config.lib.stylix.colors.base00}"; };
          };
          which = {
            mask = { bg = lib.mkForce "#${config.lib.stylix.colors.base00}"; };
          };
        };
      };
      stylix.targets.yazi.enable = true;
      stylix.targets.vesktop.enable = true;

      # Enable Vesktop for Stylix theming
      programs.vesktop = {
        enable = true;
      };

      # Override Yazi desktop file to launch via kitty
      # Using dataFile instead of desktopEntries to ensure higher priority
      xdg.dataFile."applications/yazi.desktop".text = ''
        [Desktop Entry]
        Name=Yazi
        Icon=yazi
        Comment=Blazing fast terminal file manager written in Rust, based on async I/O
        Exec=kitty -e yazi %u
        Terminal=false
        Type=Application
        MimeType=inode/directory
        Categories=Utility;Core;System;FileTools;FileManager;ConsoleOnly;
        Keywords=File;Manager;Explorer;Browser;Launcher;
      '';

      # Fastfetch configuration
      xdg.configFile."fastfetch/config.jsonc".text = builtins.toJSON {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
        logo = {
          source = "~/dotfiles/modules/desktop/AnomLogo.png";
          height = 20;
          width = 40;
        };
        modules = [
          "title"
          "separator"
          "os"
          "host"
          "kernel"
          "uptime"
          "packages"
          "shell"
          "display"
          "wm"
          "terminal"
          "cpu"
          "gpu"
          "memory"
          "swap"
          "disk"
          "break"
          "colors"
        ];
      };
    };

    # Desktop fonts
    fonts.packages = with pkgs.nerd-fonts; [
      dejavu-sans-mono
      zed-mono
      jetbrains-mono
      fira-code
      terminess-ttf
    ];
  };
}
