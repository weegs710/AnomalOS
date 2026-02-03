{...}: {
  flake.nixosModules.decky = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; let
      username = config.mySystem.user.name;
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
        users.users.${username}.packages = [decky-loader];

        # Create directories for decky
        systemd.tmpfiles.rules = [
          "d /home/${username}/homebrew 0755 ${username} users -"
          "d /home/${username}/homebrew/services 0755 ${username} users -"
          "d /home/${username}/homebrew/plugins 0755 ${username} users -"
        ];

        # Setup service that creates CEF debug files, symlinks the binary
        systemd.user.services.decky-loader-setup = {
          description = "Decky Loader Setup";
          before = ["decky-loader.service"];
          wantedBy = ["default.target"];

          script = ''
            # Create CEF remote debugging files
            mkdir -p $HOME/.steam/steam
            touch $HOME/.steam/steam/.cef-enable-remote-debugging
            mkdir -p $HOME/.var/app/com.valvesoftware.Steam/data/Steam
            touch $HOME/.var/app/com.valvesoftware.Steam/data/Steam/.cef-enable-remote-debugging

            # Symlink decky loader binary
            ln -sf ${decky-loader}/bin/PluginLoader $HOME/homebrew/services/PluginLoader
          '';

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
        };

        systemd.user.services.decky-loader = {
          description = "Decky Loader - Steam Deck plugin system";
          after = ["graphical-session.target" "decky-loader-setup.service"];
          partOf = ["graphical-session.target"];
          requires = ["decky-loader-setup.service"];
          wantedBy = ["default.target"];

          serviceConfig = {
            Type = "simple";
            ExecStart = "/home/${username}/homebrew/services/PluginLoader";
            Restart = "on-failure";
            RestartSec = "5s";
          };

          path = [
            pkgs.python3
            pkgs.systemd
            pkgs.coreutils
            pkgs.curl
            pkgs.git
          ];

          environment = {
            PLUGIN_PATH = "/home/${username}/homebrew/plugins";
            LOG_LEVEL = "INFO";
          };
        };
      };
    };
}
