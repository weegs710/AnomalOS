{
  config,
  inputs,
  only,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
  peepers = inputs.peepers.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # peepers registers its tray item once, so wait for noctalia to own the watcher before starting
  waitForTray = pkgs.writeShellScript "peepers-wait-for-tray" ''
    for _ in $(seq 60); do
      busctl --user status org.kde.StatusNotifierWatcher >/dev/null 2>&1 && exit 0
      sleep 0.5
    done
  '';
in
only.gate { tags = [ "desktop" ]; } {
  nix.settings = {
    substituters = [ "https://peepers.cachix.org" ];
    trusted-public-keys = [ "peepers.cachix.org-1:rP90IXXdICg4J7eVWuddscdW8QCobU/a945JKWcxWF8=" ];
  };

  users.users.${username}.packages = [ peepers ];

  # settings and benchmark history
  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/peepers"
    ".local/state/peepers"
  ];

  hjem.users.${username} = {
    systemd.services.peepers = {
      description = "peepers system monitor";
      after = [
        "graphical-session.target"
        "noctalia.service"
      ];
      partOf = [
        "graphical-session.target"
        "noctalia.service"
      ];
      wantedBy = [ "graphical-session.target" ];
      # commands typed into peepers' Run new task need the same programs a login shell finds
      path = [
        "/run/wrappers"
        "/etc/profiles/per-user/${username}"
        "/run/current-system/sw"
      ];
      serviceConfig = {
        # umbriel publishes the session environment after the target activates, so the unit inherits neither
        Environment = [
          "WAYLAND_DISPLAY=wayland-0"
          "DISPLAY=:0"
        ];
        ExecStartPre = waitForTray;
        ExecStart = "${peepers}/bin/peepers";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    # copy-type and writable: peepers saves its settings in place, which a read-only store link would refuse; gui edits get pulled back with `peep-s`
    xdg.config.files = {
      "peepers/settings.toml" = {
        source = ./settings.toml;
        type = "copy";
        clobber = false;
        permissions = "0644";
      };

      # noctalia renders the colours peepers' Noctalia theme reads, from the template in the pinned repo
      "noctalia/peepers.toml".text = ''
        [theme.templates.user.peepers]
        input_path  = "${inputs.peepers}/packaging/noctalia/colors.toml"
        output_path = "$XDG_CONFIG_HOME/peepers/noctalia.toml"
      '';
    };
  };
}
