{
  flake.nixosModules.desktop-packages = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.mySystem.features.desktop {
        users.users.${config.mySystem.user.name}.packages = with pkgs; [
          file-roller
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
          libx11
          libxcursor
          libxi
          libxinerama
          libxrandr
          libxxf86vm
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
    };
}
