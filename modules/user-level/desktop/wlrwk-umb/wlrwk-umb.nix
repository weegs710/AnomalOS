{
  config,
  lib,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
  yamlFormat = pkgs.formats.yaml { };

  # one-line entry builders so the tree reads as a table
  run = key: desc: cmd: { inherit key desc cmd; };
  hold = key: desc: cmd: {
    inherit key desc cmd;
    keep_open = true;
  };
  sub = key: desc: submenu: { inherit key desc submenu; };

  # Placement is declarative here, so every command is bare and the matching rule lives in umbriel's config.toml.
  shared = ../wlr-which-key;
  runPause = "${shared}/run-pause.nu";
  svcAuth = "${shared}/svc-auth.nu";
  svcUser = "${shared}/svc-user.nu";
  clipStart = "${shared}/clip-start.nu";
  clipSave = "${shared}/clip-save.nu";

  noct = cmd: "noctalia msg ${cmd}";

  # Umbriel has no exec-time placement rule, so apps whose app_id is unknown get placed by landing on the workspace first.
  onWs = n: cmd: "umbriel msg workspace-switch:${toString n} ; ${cmd}";

  terminalCmd = "ghostty --title=ghostty";
  cairnCmd = "ghostty --title=Cairn -e claude-launcher cairn";
  # helium hands off to its running pid, so a launch rule whiffs -- focus WEB instead
  heliumCmd = "umbriel msg workspace-switch:3 ; helium";
  discordCmd = "/etc/profiles/per-user/${username}/bin/vesktop";
  gajimCmd = "/etc/profiles/per-user/${username}/bin/gajim";
  btopCmd = "ghostty --title=btop -e btop";
  rmpcCmd = "ghostty --title=rmpc -e rmpc";
  fileManagerCmd = "ghostty --title=yazi -e yazi";
  tremcCmd = "ghostty --title=tremc -e tremc";
  camListCmd = "ghostty --title=cam-list -e nu ${runPause} andcam-list";

  journalCmd = "ghostty --title=journal -e journalctl -f";
  zpoolCmd = "ghostty --title=zpool -e nu ${runPause} zpool status";
  tailscaleCmd = "ghostty --title=tailscale -e nu ${runPause} tailscale status";

  # the menu owns the foreground, so the shot has to wait for it to tear down
  shotRegionCmd = "nu -c 'sleep 500ms; ^noctalia msg screenshot-region'";
  clipScreenCmd = "nu ${clipStart} screen";
  stopRecordCmd = ''nu -c 'if ("/tmp/gsr.pid" | path exists) { let pid = (open /tmp/gsr.pid | str trim | into int); ^kill -INT $pid; ^rm /tmp/gsr.pid; while (ps | where pid == $pid | is-not-empty) { sleep 100ms } }; ^wlr-which-key ~/.config/wlr-which-key/post-record.yaml' '';

  # system units restart in a float so the polkit FIDO prompt is the guard; user units just notify
  svcRestart = unit: "ghostty --title=svc-auth -e nu ${svcAuth} ${unit}";
  svcUserRestart = units: "nu ${svcUser} ${units}";
  svcStatus = unit: "ghostty --title=svc-status -e nu ${runPause} systemctl --no-pager status ${unit}";
  svcUserStatus =
    units:
    "ghostty --title=svc-status -e nu ${runPause} systemctl --user --no-pager status ${units}";

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
    # Umbriel does not implement keyboard-shortcuts-inhibit, and wlr-which-key hard-exits when the bind fails.
    inhibit_compositor_keyboard_shortcuts = false;
  };

  menus = {
    config = commonSettings // {
      rows_per_column = 9;
      menu = [
        # hot path
        (run "Return" "ghostty" terminalCmd)
        (run "space" "launcher" (noct "panel-toggle launcher"))
        (run "h" "helium" heliumCmd)
        (run "e" "zed" "zeditor")
        (run "C" "Cairn" cairnCmd)
        (run "r" "rmpc" rmpcCmd)
        (run "x" "Median XL" "d2launcher")
        # categories
        (sub "c" "comms" [
          (run "g" "gajim" gajimCmd)
          (run "d" "discord" discordCmd)
        ])
        (sub "g" "games" [
          (run "s" "steam" (onWs 4 "steam"))
          (run "h" "heroic" (onWs 4 "heroic"))
          (run "c" "Dungeon Crawl Stone Soup" (onWs 4 "crawl-tiles"))
          (run "e" "ES-DE" "es-de")
          (run "M" "AM2R" (onWs 4 "am2r"))
          (run "z" "Dusklight" (onWs 4 "dusklight"))
          (run "m" "2Ship2Harkinian" (onWs 4 "2s2h"))
          (run "l" "zelda3" (onWs 4 "zelda3"))
          (run "d" "Dinosaur Planet" (onWs 4 "dino-recomp"))
          (run "q" "Quest 64" (onWs 4 "EltaleRecompiled"))
          (run "x" "renegade x" "steam steam://rungameid/14947236508015263744")
          (sub "o" "openra" [
            (run "d" "Dune 2000" (onWs 4 "openra-d2k"))
            (run "r" "Red Alert" (onWs 4 "openra-ra"))
            (run "c" "Tiberian Dawn" (onWs 4 "openra-cnc"))
          ])
        ])
        (sub "m" "media" [
          (run "i" "inkscape" "inkscape")
          (run "g" "gimp" "gimp")
          (run "z" "zathura" (onWs 5 "zathura"))
        ])
        (sub "t" "tools" [
          (run "b" "btop" btopCmd)
          (run "y" "yazi" fileManagerCmd)
          (run "l" "lact" "lact gui")
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
          (run "r" "region" shotRegionCmd)
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
        (run "s" "save clip" "ghostty --title=name-clip -e nu ${clipSave}")
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
