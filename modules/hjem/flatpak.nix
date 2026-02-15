{inputs, ...}: {
  flake.nixosModules.flatpak = {
    config,
    lib,
    ...
  }: let
      username = config.mySystem.user.name;
    in {
      imports = [inputs.nix-flatpak.nixosModules.nix-flatpak];

      config = lib.mkIf config.mySystem.features.flatpak {
        services.flatpak = {
          enable = true;

          update = {
            onActivation = false;
            auto = {
              enable = true;
              onCalendar = "weekly";
            };
          };

          packages = [
            "com.stremio.Stremio"
          ];

          remotes = [
            {
              name = "flathub";
              location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
            }
          ];
        };

        # Flatpak overrides managed by Hjem
        hjem.users.${username} = {
          xdg.config.files."flatpak/overrides/global".text = ''
            [Context]
            sockets=wayland;!x11;!fallback-x11;pulseaudio;session-bus;system-bus;
            filesystems=xdg-download;xdg-documents;xdg-pictures;xdg-videos;
            devices=dri;

            [Environment]
            XCURSOR_PATH=/run/host/user-share/icons:/run/host/share/icons
            QT_AUTO_SCREEN_SCALE_FACTOR=1
          '';
        };
      };
    };
}
