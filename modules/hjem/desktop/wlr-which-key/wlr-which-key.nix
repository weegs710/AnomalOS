{
  config,
  lib,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
  homeDir = config.users.users.${username}.home;
  yamlFormat = pkgs.formats.yaml { };

  # one-line entry builders so the tree reads as a table
  run = key: desc: cmd: { inherit key desc cmd; };
  hold = key: desc: cmd: {
    inherit key desc cmd;
    keep_open = true;
  };
  sub = key: desc: submenu: { inherit key desc submenu; };

  hyprExec =
    cmd: rules:
    "hyprctl dispatch \"hl.dsp.exec_cmd('${cmd}'${lib.optionalString (rules != "") ", ${rules}"})\"";

  bigFloat = "{ float = true, size = {1600, 900}, move = {531, 262} }";
  midFloat = "{ float = true, size = {1200, 700}, move = {680, 370} }";
  # sized for the polkit text prompt, not general output
  authFloat = "{ float = true, size = {900, 320}, move = {830, 560} }";
  stash = "{ workspace = 'special:stash' }";

  noct = cmd: "noctalia msg ${cmd}";

  terminalCmd = "ghostty --title=ghostty";
  hexCmd = "ghostty --title=hex -e claude-launcher hex";
  jellyfinCmd = hyprExec "env MOZ_APP_LAUNCHER=zen-jellyfin zen --kiosk --profile ${homeDir}/.local/share/zen-jellyfin --no-remote http://localhost:8096" "{ workspace = '5' }";
  discordCmd = hyprExec "ghostty -e nix run nixpkgs#concord-tui" "{ workspace = '1' }";
  steamchatCmd = hyprExec "env MOZ_APP_LAUNCHER=zen-steamchat zen --profile ${homeDir}/.local/share/zen-steamchat --no-remote https://steamcommunity.com/chat" "{ workspace = '1' }";
  facebookCmd = hyprExec "zen --no-remote --new-window https://www.facebook.com" "{ workspace = 1 }";
  gajimCmd = hyprExec "/etc/profiles/per-user/${username}/bin/gajim" "";
  gorguruCmd = hyprExec "ghostty --title=gorguru -e ${homeDir}/repo/private/weegs.dev/dist/gorguru" stash;
  btopCmd = hyprExec "ghostty --title=btop -e btop" bigFloat;
  rmpcCmd = hyprExec "ghostty --title=rmpc -e rmpc" "";
  fileManagerCmd = hyprExec "ghostty -e yazi" bigFloat;
  tremcCmd = hyprExec "ghostty --title=tremc -e tremc" bigFloat;
  camListCmd = hyprExec "ghostty --title=cam-list -e nu ${./run-pause.nu} andcam-list" midFloat;

  journalCmd = hyprExec "ghostty --title=journal -e journalctl -f" stash;
  zpoolCmd = hyprExec "ghostty --title=zpool -e nu ${./run-pause.nu} zpool status" midFloat;
  tailscaleCmd = hyprExec "ghostty --title=tailscale -e nu ${./run-pause.nu} tailscale status" midFloat;

  shotRegionClipCmd = "nu -c 'sleep 500ms; ^hyprshot -m region -z --clipboard-only'";
  shotWindowClipCmd = "nu -c 'sleep 500ms; ^hyprshot -m window -z --clipboard-only'";
  shotScreenClipCmd = "nu -c 'sleep 500ms; ^hyprshot -m output -z --clipboard-only'";
  shotRegionSaveCmd = ''nu -c 'sleep 500ms; let fn = $"/tmp/wkshot_(random int).png"; ^hyprshot -m region -z --raw | save --raw $fn; ^ghostty --title=name-shot -e nu ${./shot-save.nu} $fn' '';
  shotWindowSaveCmd = ''nu -c 'sleep 500ms; let fn = $"/tmp/wkshot_(random int).png"; ^hyprshot -m window -z --raw | save --raw $fn; ^ghostty --title=name-shot -e nu ${./shot-save.nu} $fn' '';
  shotScreenSaveCmd = ''nu -c 'sleep 500ms; let fn = $"/tmp/wkshot_(random int).png"; ^hyprshot -m output -z --raw | save --raw $fn; ^ghostty --title=name-shot -e nu ${./shot-save.nu} $fn' '';
  clipScreenCmd = "nu ${./clip-start.nu} screen";
  stopRecordCmd = ''nu -c 'if ("/tmp/gsr.pid" | path exists) { let pid = (open /tmp/gsr.pid | str trim | into int); ^kill -INT $pid; ^rm /tmp/gsr.pid; while (ps | where pid == $pid | is-not-empty) { sleep 100ms } }; ^wlr-which-key ~/.config/wlr-which-key/post-record.yaml' '';

  # system units restart in a float so the polkit FIDO prompt is the guard; user units just notify
  svcRestart = unit: hyprExec "ghostty --title=svc-auth -e nu ${./svc-auth.nu} ${unit}" authFloat;
  svcUserRestart = units: "nu ${./svc-user.nu} ${units}";
  svcStatus =
    unit:
    hyprExec "ghostty --title=svc-status -e nu ${./run-pause.nu} systemctl --no-pager status ${unit}" midFloat;
  svcUserStatus =
    units:
    hyprExec "ghostty --title=svc-status -e nu ${./run-pause.nu} systemctl --user --no-pager status ${units}" midFloat;

  systemUnits = [
    {
      key = "j";
      unit = "jellyfin";
    }
    {
      key = "n";
      unit = "navidrome";
    }
    {
      key = "t";
      unit = "transmission";
    }
    {
      key = "s";
      unit = "sonarr";
    }
    {
      key = "r";
      unit = "radarr";
    }
    {
      key = "p";
      unit = "prowlarr";
    }
    {
      key = "b";
      unit = "bazarr";
    }
    {
      key = "f";
      unit = "flaresolverr";
    }
    {
      key = "a";
      unit = "tailscaled";
    }
    {
      key = "c";
      unit = "scrcpy-cam";
    }
  ];
  userUnits = [
    {
      key = "m";
      unit = "mpd";
    }
    {
      key = "w";
      unit = "weegs-dev";
    }
    {
      key = "d";
      unit = "decky-loader";
    }
    {
      key = "k";
      unit = "nushell-book";
    }
    {
      key = "x";
      unit = "xdg-desktop-portal xdg-desktop-portal-gtk";
      desc = "xdg portals";
    }
    {
      key = "i";
      unit = "wireplumber";
    }
  ];
  restartEntries =
    map (u: run u.key (u.desc or u.unit) (svcRestart u.unit)) systemUnits
    ++ map (u: run u.key (u.desc or u.unit) (svcUserRestart u.unit)) userUnits;
  statusEntries =
    map (u: run u.key (u.desc or u.unit) (svcStatus u.unit)) systemUnits
    ++ map (u: run u.key (u.desc or u.unit) (svcUserStatus u.unit)) userUnits;

  # hardcoded to match noctalia's Eldritch palette -- update these hex if the colorscheme changes
  commonSettings = {
    font = "JetBrainsMono Nerd Font 12";
    background = "#212337e6";
    color = "#ebfafa";
    border = "#37f499";
    separator = " ➜ ";
    border_width = 2;
    corner_r = 8;
    padding = 15;
    anchor = "center";
    inhibit_compositor_keyboard_shortcuts = true;
  };

  menus = {
    config = commonSettings // {
      rows_per_column = 9;
      menu = [
        # hot path
        (run "Return" "ghostty" terminalCmd)
        (run "space" "launcher" (noct "panel-toggle launcher"))
        (run "z" "zen" "zen")
        (run "e" "zed" "zeditor")
        (run "h" "hex" hexCmd)
        (run "r" "rmpc" rmpcCmd)
        (run "j" "jellyfin" jellyfinCmd)
        (run "x" "Median XL" "d2launcher")
        # categories
        (sub "c" "comms" [
          (run "g" "gajim" gajimCmd)
          (run "d" "discord" discordCmd)
          (run "s" "steam chat" steamchatCmd)
          (run "f" "facebook" facebookCmd)
        ])
        (sub "g" "games" [
          (run "s" "steam" "steam")
          (run "h" "heroic" "heroic")
          (run "g" "gorguru" gorguruCmd)
          (run "c" "Dungeon Crawl Stone Soup" "crawl-tiles")
          (run "r" "retroarch" "retroarch")
          (run "m" "AM2R" "am2r")
          (run "x" "renegade x" "steam steam://rungameid/14947236508015263744")
          (sub "o" "openra" [
            (run "d" "Dune 2000" "openra-d2k")
            (run "r" "Red Alert" "openra-ra")
            (run "c" "Tiberian Dawn" "openra-cnc")
          ])
        ])
        (sub "m" "media" [
          (run "i" "inkscape" "inkscape")
          (run "g" "gimp" "gimp")
          (run "z" "zathura" "zathura")
        ])
        (sub "t" "tools" [
          (run "b" "btop" btopCmd)
          (run "y" "yazi" fileManagerCmd)
          (run "l" "lact" "lact gui")
          (run "m" "piper" "piper")
          (run "p" "gparted" "gparted")
          (run "t" "protontricks" "protontricks --no-term --gui")
          (run "u" "protonup-qt" "protonup-qt")
          (run "x" "transmission" tremcCmd)
          (sub "c" "cam" [
            (run "o" "cam on" "andcam-start")
            (run "x" "cam off" "pkill scrcpy")
            (run "d" "cam daemon" "andcam-daemon")
            (run "l" "cam list" camListCmd)
          ])
        ])
        (sub "a" "audio" [
          (hold "Left" "vol down" (noct "volume-down"))
          (hold "Right" "vol up" (noct "volume-up"))
          (hold "Up" "vol 100%" (noct "volume-set 100"))
          (hold "Down" "mute" (noct "volume-mute"))
          (hold "Prior" "prev track" (noct "media previous"))
          (hold "Next" "next track" (noct "media next"))
          (hold "space" "play/pause" (noct "media toggle"))
          (hold "x" "stop" (noct "media stop"))
          (sub "m" "mic" [
            (hold "Left" "mic down" (noct "mic-volume-down"))
            (hold "Right" "mic up" (noct "mic-volume-up"))
            (hold "Up" "mic 100%" (noct "mic-volume-set 100"))
            (hold "Down" "mic mute" (noct "mic-mute"))
          ])
        ])
        (sub "n" "notify" [
          (hold "d" "dnd toggle" (noct "notification-dnd-toggle"))
          (run "c" "clear active" (noct "notification-clear-active"))
          (run "C" "clear history" (noct "notification-clear-history"))
          (run "x" "clipboard clear" (noct "clipboard-clear"))
        ])
        (sub "w" "wireless" [
          (hold "w" "wifi toggle" (noct "wifi-toggle"))
          (hold "b" "bluetooth toggle" (noct "bluetooth-toggle"))
        ])
        (sub "v" "services" [
          (sub "r" "restart" restartEntries)
          (sub "s" "status" statusEntries)
          (sub "m" "monitor" [
            (run "j" "journal follow" journalCmd)
            (run "z" "zpool status" zpoolCmd)
            (run "t" "tailscale status" tailscaleCmd)
          ])
        ])
        (sub "s" "capture" [
          (run "x" "stop recording" stopRecordCmd)
          (run "r" "region → clipboard" shotRegionClipCmd)
          (run "w" "window → clipboard" shotWindowClipCmd)
          (run "s" "screen → clipboard" shotScreenClipCmd)
          (sub "f" "save to file" [
            (run "r" "region" shotRegionSaveCmd)
            (run "w" "window" shotWindowSaveCmd)
            (run "s" "screen" shotScreenSaveCmd)
          ])
          (run "c" "start recording" clipScreenCmd)
        ])
        (sub "q" "session" [
          (run "l" "lock" (noct "session lock"))
          (run "o" "logout" (noct "session logout"))
          (run "r" "reboot" (noct "session reboot"))
          (run "s" "shutdown" (noct "session shutdown"))
        ])
      ];
    };

    "post-record" = commonSettings // {
      menu = [
        (run "s" "save clip" "ghostty --title=name-clip -e nu ${./clip-save.nu}")
        (run "d" "discard" "rm -f /tmp/gsr_clip.mp4")
      ];
    };
  };
in
{
  users.users.${username}.packages = [
    pkgs.wlr-which-key
    pkgs.libwebp
  ];

  hjem.users.${username}.xdg.config.files = lib.mapAttrs' (
    name: cfg:
    lib.nameValuePair "wlr-which-key/${name}.yaml" {
      source = yamlFormat.generate "${name}.yaml" cfg;
    }
  ) menus;
}
