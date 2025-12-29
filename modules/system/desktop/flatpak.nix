{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.flatpak {
    services.flatpak = {
      enable = true;
    };

    home-manager.users.${config.mySystem.user.name} = {
      imports = [
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
      ];

      services.flatpak = {
        enable = true;

        packages = [
          "com.stremio.Stremio"
        ];

        remotes = [
          {
            name = "flathub";
            location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
          }
        ];

        update = {
          onActivation = false;
          auto = {
            enable = true;
            onCalendar = "weekly";
          };
        };

        overrides = {
          global = {
            Context = {
              sockets = [
                "wayland"
                "!x11"
                "!fallback-x11"
                "pulseaudio"
                "session-bus"
                "system-bus"
              ];

              filesystems = [
                "xdg-download"
                "xdg-documents"
                "xdg-pictures"
                "xdg-videos"
              ];

              devices = ["dri"];
            };

            Environment = {
              XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";
              QT_AUTO_SCREEN_SCALE_FACTOR = "1";
            };
          };
        };

        uninstallUnmanaged = true;
        uninstallUnused = true;
      };
    };
  };
}
