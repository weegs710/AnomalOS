{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [
    ./audio.nix
    ./autotrash.nix
    ./btop.nix
    ./flatpak.nix
    ./hyprland.nix
    ./kdeconnect.nix
    ./media.nix
    ./mpd.nix
    ./pulsemixer.nix
    ./qalc.nix
    ./timg.nix
  ];

  config = mkIf config.mySystem.features.desktop {
    services = {
      displayManager = {
        defaultSession = "hyprland";
        ly = {
          enable = true;
        };
      };
      blueman.enable = true;
      upower.enable = true;
      ratbagd.enable = true;
      udisks2.enable = true;
      locate.enable = true;
    };

    programs = {
      partition-manager.enable = true;
    };

    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      file-roller
      kdePackages.okular
      qview
      transmission_4-gtk
      unzipNLS
      bluetui
      fastfetch
      gparted
      piper
      adwaita-icon-theme
      dbus
      dbus-broker
      libGL
      libnotify
      libportal
      lm_sensors
      mesa
      xdg-dbus-proxy
      cliphist
      ueberzugpp
      xorg.libX11
      xorg.libXcursor
      xorg.libXi
      xorg.libXinerama
      xorg.libXrandr
      xorg.libXxf86vm
    ];

    environment.shellAliases = {
      gparted = "sudo WAYLAND_DISPLAY=$WAYLAND_DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR gparted";
    };

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
