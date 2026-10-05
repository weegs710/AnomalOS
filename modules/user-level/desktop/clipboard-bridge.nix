{
  pkgs,
  ...
}:
let
  # umbriel's XWM mirrors X -> Wayland but never the reverse, so Xwayland clients see no desktop copy
  bridge = pkgs.writeShellScript "wl-to-x-clipboard" ''
    exec ${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.runtimeShell} -c '
      new=$(cat)
      [ -z "$new" ] && exit 0
      # skip when X already holds it, so an X-sourced copy cannot ping-pong back through the mirror
      cur=$(${pkgs.xclip}/bin/xclip -selection clipboard -o 2>/dev/null)
      [ "$new" = "$cur" ] && exit 0
      printf %s "$new" | ${pkgs.xclip}/bin/xclip -selection clipboard -i
    '
  '';
in
{
  systemd.user.services.wl-to-x-clipboard = {
    description = "Mirror the Wayland clipboard onto X11 for Xwayland clients";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];

    # umbriel publishes the session environment after the target activates, so the unit inherits neither
    environment = {
      WAYLAND_DISPLAY = "wayland-0";
      DISPLAY = ":0";
    };

    serviceConfig = {
      Type = "simple";
      ExecStart = bridge;
      Restart = "always";
      RestartSec = 2;
    };
  };
}
