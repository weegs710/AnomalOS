{...}: {
  flake.nixosModules.gaming-mode = {
    config,
    lib,
    pkgs,
    ...
  }: let
    sessionSelect = pkgs.writeTextFile {
      name = "steamos-session-select";
      executable = true;
      destination = "/bin/steamos-session-select";
      text = ''
        #!${pkgs.nushell}/bin/nu
        def main [target: string] {
          $target | save -f /tmp/steamos-session-target
          pkill -TERM gamescope
        }
      '';
    };

    sessionLoop = pkgs.writeTextFile {
      name = "deck-session-loop";
      executable = true;
      destination = "/bin/deck-session-loop";
      text = ''
        #!${pkgs.nushell}/bin/nu
        def main [] {
          $env.XDG_SESSION_TYPE = "wayland"
          $env.XDG_RUNTIME_DIR = $"/run/user/(^id -u | str trim)"
          $env.STEAM_FORCE_DESKTOPUI_SCALING = "1.25"
          $env.STEAM_GAMEPADUI = "1"

          loop {
            rm -f /tmp/steamos-session-target

            ^${pkgs.gamescope}/bin/gamescope \
              -W 1280 -H 800 \
              --fullscreen \
              --steam \
              --xwayland-count 2 \
              --default-touch-mode 4 \
              --hide-cursor-delay 3000 \
              --framerate-limit 60 \
              --rt \
              -e \
              -- ${pkgs.steam}/bin/steam -gamepadui -steamos -steamos3 -steamdeck

            let target = try { open /tmp/steamos-session-target | str trim } catch { "gamescope" }

            if $target == "desktop" {
              ^${pkgs.hyprland}/bin/Hyprland
            }
          }
        }
      '';
    };
  in {
    config = lib.mkIf config.mySystem.features.steamdeck {
      environment.systemPackages = [sessionSelect sessionLoop];

      services.greetd = {
        enable = true;
        settings = {
          initial_session = {
            command = "${sessionLoop}/bin/deck-session-loop";
            user = config.mySystem.user.name;
          };
          default_session = {
            command = "${sessionLoop}/bin/deck-session-loop";
            user = config.mySystem.user.name;
          };
        };
      };

      security.wrappers.gamescope = {
        owner = "root";
        group = "root";
        capabilities = "cap_sys_nice+eip";
        source = "${pkgs.gamescope}/bin/gamescope";
      };
    };
  };
}
