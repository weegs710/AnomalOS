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

        hjem.users.${username} = {
          xdg.config.files."noctalia/settings.json" = {
            source = ./settings.json;
            type = "copy";
            permissions = "0644";
          };
        };
      };
    };
}
