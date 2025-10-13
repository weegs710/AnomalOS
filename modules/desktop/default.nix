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
      mpv
      pavucontrol
      qalculate-gtk
      qview
      transmission_4-gtk
      unzipNLS
      vesktop
      yazi
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
      ff = "fastfetch --logo ~/Pictures/nixos-pics/nixos.png --logo-height 20 --logo-width 40";
      gparted = "sudo WAYLAND_DISPLAY=$WAYLAND_DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR gparted";
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
