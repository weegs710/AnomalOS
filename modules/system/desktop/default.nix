# Desktop environment configuration
# Wayland-based desktop with Hyprland compositor, SDDM, and PipeWire audio
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
    ./mpd.nix
    ./rofi.nix
    ./flatpak.nix
    ./kdeconnect.nix
    ./autotrash.nix
    ./brave.nix
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
    };

    services = {
      blueman.enable = true;
      upower.enable = true;
      ratbagd.enable = true;
      udisks2.enable = true;
      locate.enable = true;
    };

    # KWallet PAM integration (SDDM delegates to login stack)
    security.pam.services.login.kwallet = {
      enable = true;
      package = pkgs.kdePackages.kwallet-pam;
    };

    programs = {
      partition-manager.enable = true;
    };

    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      # Applications
      file-roller
      kdePackages.okular
      pavucontrol
      qalculate-gtk
      qview
      transmission_4-gtk
      unzipNLS
      # cavalier

      # Utilities
      bluetui
      fastfetch
      gparted
      piper

      # System libraries and support
      adwaita-icon-theme
      dbus
      dbus-broker
      kdePackages.kwallet
      kdePackages.kwallet-pam
      kdePackages.kwalletmanager
      libGL
      libnotify
      libportal
      lm_sensors
      mesa
      wireplumber
      xdg-dbus-proxy

      # Terminal and system utilities
      cliphist
      pamixer
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


    # Desktop fonts
    fonts.packages = with pkgs.nerd-fonts; [
      dejavu-sans-mono
      zed-mono
      jetbrains-mono
      fira-code
      terminess-ttf
      space-mono
      hack
      iosevka
    ];
  };
}
