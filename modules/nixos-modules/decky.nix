{...}: {
  flake.nixosModules.decky = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; let
      deckyVersion = "3.2.1";

      decky-loader = pkgs.stdenv.mkDerivation {
        pname = "decky-loader";
        version = deckyVersion;

        src = pkgs.fetchurl {
          url = "https://github.com/SteamDeckHomebrew/decky-loader/releases/download/v${deckyVersion}/PluginLoader";
          hash = "sha256-LiqNn/zg8zdP3IvAW7dSgWiRjIPFvQccD8L61G5FAXc=";
        };

        dontUnpack = true;
        dontBuild = true;

        nativeBuildInputs = [pkgs.autoPatchelfHook];
        buildInputs = [
          pkgs.zlib
          pkgs.stdenv.cc.cc.lib
        ];

        installPhase = ''
          mkdir -p $out/bin
          cp $src $out/bin/PluginLoader
          chmod +x $out/bin/PluginLoader
        '';

        meta = with lib; {
          description = "Plugin loader for Steam Deck";
          homepage = "https://github.com/SteamDeckHomebrew/decky-loader";
          license = licenses.gpl2;
          platforms = platforms.linux;
        };

        passthru.updateScript = pkgs.writeShellScript "update-decky-loader" ''
          #!/usr/bin/env bash
          set -euo pipefail

          LATEST_VERSION=$(${pkgs.curl}/bin/curl -s https://api.github.com/repos/SteamDeckHomebrew/decky-loader/releases/latest | ${pkgs.jq}/bin/jq -r .tag_name | sed 's/^v//')

          HASH=$(${pkgs.nurl}/bin/nurl "https://github.com/SteamDeckHomebrew/decky-loader/releases/download/v$LATEST_VERSION/PluginLoader" 2>&1 | grep -oP 'hash = "\K[^"]+')

          FILE="${toString ./.}/modules/gaming/decky-loader.nix"
          ${pkgs.gnused}/bin/sed -i "s/deckyVersion = \"[^\"]*\"/deckyVersion = \"$LATEST_VERSION\"/" "$FILE"
          ${pkgs.gnused}/bin/sed -i "s|hash = \"[^\"]*\"|hash = \"$HASH\"|" "$FILE" || \
          ${pkgs.gnused}/bin/sed -i "s|hash = lib.fakeHash|hash = \"$HASH\"|" "$FILE"

          echo "Updated Decky Loader to version $LATEST_VERSION with hash $HASH"
        '';
      };
    in {
      config = mkIf config.mySystem.features.gaming {
        home-manager.users.${config.mySystem.user.name} = {
          home.packages = [decky-loader];

          home.file.".steam/steam/.cef-enable-remote-debugging".text = "";
          home.file.".var/app/com.valvesoftware.Steam/data/Steam/.cef-enable-remote-debugging".text = "";

          home.activation.createDeckyDirectories = ''
            mkdir -p $HOME/homebrew/services
            mkdir -p $HOME/homebrew/plugins
            ln -sf ${decky-loader}/bin/PluginLoader $HOME/homebrew/services/PluginLoader
          '';

          systemd.user.services.decky-loader = {
            Unit = {
              Description = "Decky Loader - Steam Deck plugin system";
              After = ["graphical-session.target"];
              PartOf = ["graphical-session.target"];
            };
            Service = {
              Type = "simple";
              ExecStart = "%h/homebrew/services/PluginLoader";
              Restart = "on-failure";
              RestartSec = "5s";
              Environment = [
                "PLUGIN_PATH=%h/homebrew/plugins"
                "LOG_LEVEL=INFO"
                "PATH=${lib.makeBinPath [
                  pkgs.python3
                  pkgs.systemd
                  pkgs.coreutils
                  pkgs.curl
                  pkgs.git
                ]}:/run/current-system/sw/bin:/run/wrappers/bin"
              ];
            };
            Install = {
              WantedBy = ["default.target"];
            };
          };
        };
      };
    };
}
