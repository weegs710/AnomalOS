{
  flake.nixosModules.heroic = {
    config,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
  in {
    users.users.${username}.packages = [pkgs.heroic];

    hjem.users.${username} = {
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
          customWinePaths = [];
          defaultInstallPath = "/mnt/games/heroic";
          libraryTopSection = "disabled";
          defaultSteamPath = "/home/weegs/.steam/steam";
          defaultWinePrefix = "/mnt/games/heroic/Prefixes/default";
          hideChangelogsOnStartup = true;
          language = "en";
          maxWorkers = 0;
          minimizeOnLaunch = false;
          nvidiaPrime = false;
          enviromentOptions = [];
          wrapperOptions = [];
          showFps = false;
          useGameMode = false;
          wineCrossoverBottle = "Heroic";
          winePrefix = "/mnt/games/heroic/Prefixes/default";
          wineVersion = {
            bin = "/home/weegs/.local/share/Steam/compatibilitytools.d/GE-Proton10-28/proton";
            name = "GE-Proton10-28";
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
        };
      };
    };
  };
}
