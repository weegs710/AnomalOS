{
  flake.nixosModules.desktop-packages = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.mySystem.features.desktop {
      users.users.${config.mySystem.user.name}.packages = with pkgs; [
        adwaita-icon-theme
        bluetui
        cliphist
        dbus
        dbus-broker
        file-roller
        gajim
        gparted
        libGL
        libnotify
        libportal
        libx11
        libxcursor
        libxi
        libxinerama
        libxrandr
        libxxf86vm
        lm_sensors
        mesa
        piper
        qview
        transmission_4-gtk
        ueberzugpp
        unzipNLS
        xdg-dbus-proxy
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
