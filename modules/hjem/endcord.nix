{
  inputs,
  ...
}:
{
  flake.nixosModules.endcord =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      username = config.mySystem.user.name;
      endcord = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.endcord;

      # Prevents system mimeapps from routing Discord media to unintended apps.
      endcordXdgOpen = pkgs.writeShellScriptBin "xdg-open" ''
        arg="$1"
        ext="''${arg##*.}"
        ext="''${ext,,}"
        case "$ext" in
          jpg|jpeg|png|gif|webp|bmp|tiff|svg|ico|avif)
            exec ${pkgs.qview}/bin/qview "$arg" >/dev/null 2>&1 ;;
          mp4|mkv|webm|avi|mov|flv|wmv|m4v|3gp|ogv)
            exec ${pkgs.mpv}/bin/mpv "$arg" >/dev/null 2>&1 ;;
          mp3|ogg|flac|wav|m4a|aac|opus|weba)
            exec ${pkgs.mpv}/bin/mpv "$arg" >/dev/null 2>&1 ;;
          *)
            exec ${pkgs.xdg-utils}/bin/xdg-open "$arg" >/dev/null 2>&1 ;;
        esac
      '';

      # Layered over the shareables binary so media app preferences stay at hjem level.
      endcordWrapped = pkgs.writeShellScriptBin "endcord" ''
        export PATH="${lib.makeBinPath [ endcordXdgOpen ]}:$PATH"
        exec ${endcord}/bin/endcord "$@"
      '';
    in
    {
      users.users.${username}.packages = [ endcordWrapped ];

      hjem.users.${username} = {
        # Endcord merges missing keys from its defaults at runtime without writing back to this file.
        # See: https://github.com/sparklost/endcord/blob/main/docs/configuration.md
        xdg.config.files."endcord/config.ini".text = ''
          [main]
          native_file_dialog = False
          native_media_player = True
          limit_channel_cache = 20
          ack_throttling = 8

          [keybindings]
          # Ctrl+V (code 22, default) is intercepted by ghostty for paste; Alt+Y mirrors the Windows platform override
          # See: https://github.com/sparklost/endcord/blob/main/endcord/defaults.py
          view_media = ALT+121

          [command_bindings]
          ALT+97 = voice_accept_call
          ALT+108 = voice_leave_call
          ALT+100 = voice_reject_call
          ALT+99 = voice_list_call
        '';
      };

      system.activationScripts.endcord-profile = lib.stringAfter [ "agenix" ] ''
        # /persist directly avoids bind-mount ordering ambiguity during activation.
        profiles_path="/persist/home/${username}/.config/endcord/profiles.json"

        if [ ! -f "$profiles_path" ]; then
          mkdir -p "$(dirname "$profiles_path")"

          token=$(cat ${config.age.secrets.discord-token.path})

          # "selected" must match a profile name; endcord uses it to skip the login UI at startup.
          # See: https://github.com/sparklost/endcord/blob/main/endcord/profile_manager.py
          printf '{"selected":"%s","profiles":[{"name":"%s","token":"%s","time":0}]}\n' \
            "${username}" "${username}" "$token" > "$profiles_path"

          chmod 600 "$profiles_path"
          chown ${username}: "$profiles_path"
        fi
      '';
    };
}
