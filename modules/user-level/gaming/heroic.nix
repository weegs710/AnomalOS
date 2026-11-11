{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
  homeDir = config.users.users.${username}.home;
  inherit (config.mySystem) display;
in
{
  users.users.${username}.packages = [ pkgs.heroic ];

  hjem.users.${username} = {
    # kept as a nix attrset, not an extracted json: the attrset is the source, json would just be its generated output
    xdg.config.files."heroic/config.json".text = builtins.toJSON {
      version = "v0";
      defaultSettings = {
        analyticsOptIn = false;
        checkUpdatesInterval = 10;
        enableUpdates = false;
        addDesktopShortcuts = false;
        addStartMenuShortcuts = false;
        autoInstallDxvk = true;
        autoInstallVkd3d = true;
        autoInstallDxvkNvapi = true;
        addSteamShortcuts = false;
        preferSystemLibs = false;
        checkForUpdatesOnStartup = false;
        autoUpdateGames = true;
        customWinePaths = [ ];
        defaultInstallPath = "${config.mySystem.paths.games}/heroic";
        libraryTopSection = "disabled";
        defaultSteamPath = "${homeDir}/.steam/steam";
        defaultWinePrefix = "${config.mySystem.paths.games}/heroic/Prefixes/default";
        hideChangelogsOnStartup = true;
        language = "en";
        maxWorkers = 0;
        minimizeOnLaunch = false;
        nvidiaPrime = false;
        enviromentOptions = [ ];
        wrapperOptions = [ ];
        showFps = false;
        useGameMode = false;
        wineCrossoverBottle = "Heroic";
        winePrefix = "${config.mySystem.paths.games}/heroic/Prefixes/default";
        wineVersion = {
          bin = "${homeDir}/.local/share/Steam/compatibilitytools.d/GE-Proton10-34/proton";
          name = "GE-Proton10-34";
          type = "proton";
        };
        enableEsync = true;
        enableFsync = true;
        enableMsync = false;
        enableWineWayland = false;
        enableHDR = false;
        enableWoW64 = false;
        eacRuntime = true;
        battlEyeRuntime = true;
        framelessWindow = false;
        beforeLaunchScriptPath = "";
        afterLaunchScriptPath = "";
        disableUMU = false;
        verboseLogs = true;
        downloadProtonToSteam = false;
        advertiseAvxForRosetta = false;
        noTrayIcon = false;
        showValveProton = false;
        exitToTray = true;
        darkTrayIcon = true;
        egsLinkedPath = "";
        gamescope = {
          enableUpscaling = false;
          enableLimiter = true;
          enableForceGrabCursor = false;
          windowType = "borderless";
          gameWidth = "";
          gameHeight = "";
          upscaleHeight = "";
          upscaleWidth = "";
          upscaleMethod = "fsr";
          fpsLimiter = toString display.refresh;
          fpsLimiterNoFocus = "";
          # -W/-H needed when upscaling disabled
          additionalOptions = "-W ${toString display.width} -H ${toString display.height} --backend wayland";
        };
      };
    };
  };

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/heroic"
    ".local/state/Heroic"
  ];
}
