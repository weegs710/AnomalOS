{
  flake.nixosModules.noctalia = {
    config,
    lib,
    pkgs,
    inputs,
    ...
  }: let
    username = config.mySystem.user.name;
    system = pkgs.stdenv.hostPlatform.system;
    restartScript = pkgs.writeTextFile {
      name = "noctalia-restart";
      executable = true;
      text = ''
        #!${pkgs.nushell}/bin/nu
        if (^${pkgs.procps}/bin/pgrep quickshell | complete).exit_code != 0 { exit }
        ^${pkgs.procps}/bin/pkill quickshell
        sleep 500ms
        ^${pkgs.tmux}/bin/tmux new-session -d /etc/profiles/per-user/${username}/bin/noctalia-shell
      '';
    };
    noctalia-shell = pkgs.symlinkJoin {
      name = "noctalia-shell";
      paths = [ inputs.noctalia-shell.packages.${system}.default ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/noctalia-shell \
          --prefix QT_PLUGIN_PATH : ${pkgs.qt6Packages.qtimageformats}/lib/qt-6/plugins
      '';
    };
  in {
    config = lib.mkIf config.mySystem.features.desktop {
        users.users.${username}.packages = [
          noctalia-shell
          inputs.noctalia-qs.packages.${system}.default
          pkgs.qt6Packages.qt6ct
        ];

        environment.sessionVariables = {
          QT_QPA_PLATFORMTHEME = "qt6ct";
        };

        systemd.user.paths.noctalia-restart = {
          description = "Watch for system rebuild to restart noctalia-shell";
          wantedBy = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          pathConfig.PathChanged = "/run/current-system";
        };

        systemd.user.services.noctalia-restart = {
          description = "Restart noctalia-shell after rebuild";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${restartScript}";
          };
        };

        hjem.users.${username} = {
          xdg.config.files."noctalia/settings.json" = {
            source = ./settings.json;
            type = "copy";
            permissions = "0644";
          };
          xdg.config.files."noctalia/user-templates.toml" = {
            source = ./user-templates.toml;
            type = "copy";
            permissions = "0644";
          };
          xdg.config.files."noctalia/templates/fresh.json" = {
            source = ./templates/fresh.json;
            type = "copy";
            permissions = "0644";
          };
        };
      };
    };
}
