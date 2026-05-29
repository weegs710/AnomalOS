{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  username = config.mySystem.user.name;
  system = pkgs.stdenv.hostPlatform.system;
  notificationHistoryAllowedApps = [ "helium" ];
  notificationAllowlist = pkgs.writeText "notification-allowlist" (
    lib.concatStringsSep "\n" notificationHistoryAllowedApps
  );
  patchedNoctalia = inputs.noctalia-shell.packages.${system}.default.overrideAttrs (prev: {
    postPatch = (prev.postPatch or "") + ''
      bash ${./patch-notification-service.sh}
    '';
  });
  noctalia-shell = pkgs.symlinkJoin {
    name = "noctalia-shell";
    paths = [ patchedNoctalia ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/noctalia-shell \
        --prefix QT_PLUGIN_PATH : ${pkgs.qt6Packages.qtimageformats}/lib/qt-6/plugins
    '';
  };
in
{
  users.users.${username}.packages = [
    noctalia-shell
    inputs.noctalia-qs.packages.${system}.default
    pkgs.qt6Packages.qt6ct
  ];

  environment.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };

  system.activationScripts.noctaliaRestartTrigger = {
    text = ''
      uid=$(${pkgs.coreutils}/bin/id -u ${username} 2>/dev/null)
      if [ -n "$uid" ] && [ -d /run/user/$uid/hypr ]; then
        XDG_RUNTIME_DIR=/run/user/$uid \
        ${pkgs.util-linux}/bin/runuser -u ${username} -- \
          ${pkgs.hyprland}/bin/hyprctl -i 0 dispatch exec \
          "${pkgs.nushell}/bin/nu --config /home/${username}/.config/nushell/config.nu --env-config /home/${username}/.config/nushell/env.nu -c noct-r >> /home/${username}/.local/state/noctalia-restart.log 2>&1" || true
      fi
    '';
  };

  hjem.users.${username} = {
    xdg.config.files."noctalia/settings.json" = {
      source = ./settings.json;
      type = "copy";
      permissions = "0644";
    };

    xdg.config.files."noctalia/notification-allowlist" = {
      source = notificationAllowlist;
      type = "copy";
      permissions = "0644";
    };
  };
}
