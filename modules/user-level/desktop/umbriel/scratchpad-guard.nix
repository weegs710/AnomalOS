{
  config,
  pkgs,
  only,
  ...
}:
let
  guard = pkgs.writeShellApplication {
    name = "umbriel-scratchpad-guard";
    # a unit's PATH is only coreutils, findutils, gnugrep, gnused and systemd, so the rest is pinned
    runtimeInputs = [
      pkgs.jq
      pkgs.socat
    ];
    text = builtins.readFile ./scratchpad-guard.sh;
  };
in
only.gate { tags = [ "desktop" ]; } {
  hjem.users.${config.mySystem.user.name}.systemd.services.umbriel-scratchpad-guard = {
    description = "Put umbriel scratchpad windows back where they were after a monitor reconnect";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];

    # umbriel publishes the session environment after the target activates, so the unit inherits none of it
    environment.WAYLAND_DISPLAY = "wayland-0";

    serviceConfig = {
      ExecStart = "${guard}/bin/umbriel-scratchpad-guard";
      Restart = "always";
      RestartSec = 2;
    };
  };
}
