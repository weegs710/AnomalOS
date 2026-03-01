{inputs, ...}: {
  flake.nixosModules.endcord = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;

    # layer-wrap the portable shareable with system-specific xdg-open behaviour
    xdgOpenWrapper = pkgs.writeShellScriptBin "xdg-open" ''
      URL="$1"
      if [[ -f "$URL" ]]; then
        MIME=$(${pkgs.file}/bin/file --mime-type -b "$URL")
        if [[ "$MIME" == image/* ]]; then
          ${pkgs.qview}/bin/qview "$URL" &
          disown
          exit 0
        fi
      fi
      if [[ "$URL" =~ ^https?:// ]]; then
        exec helium --new-window "$URL"
      fi
      exec ${pkgs.xdg-utils}/bin/xdg-open "$URL"
    '';

    endcord = pkgs.symlinkJoin {
      name = "endcord-system";
      paths = [inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.endcord];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/endcord \
          --prefix PATH : ${pkgs.lib.makeBinPath [xdgOpenWrapper]}
      '';
      meta.mainProgram = "endcord";
    };
  in {
    config = lib.mkIf config.mySystem.features.desktop {
      users.users.${username}.packages = [endcord];

      hjem.users.${username} = {
        xdg.config.files."endcord/config.ini".text = ''
          [main]
          theme = "noctalia"
          native_media_player = True
          keep_deleted = True
          rpc = False
          game_detection = False

          [keybindings]
          tree_up = 573
          tree_down = 532
          extra_up = 575
          extra_down = 534
          redo = 25
          view_media = "ALT+115"
          show_pinned = 16
          toggle_ping = "ALT+98"
          toggle_member_list = 21
          upload = "ALT+117"
          copy_message_link = "ALT+108"

          [command_bindings]
          "552" = "switch_tab prev"
          "567" = "switch_tab next"
          "336" = "tree_select server; collapse_all_except selected"
          "337" = "tree_select server prev; collapse_all_except selected"
        '';

        xdg.config.files."endcord/Themes/noctalia.ini".text = ''
          [theme]
          media_use_blocks = True
          media_color_bg = 0

          color_chat_mention = [3, 0]
          color_chat_blocked = [8, -1]
          color_chat_deleted = [9, -1]
          color_chat_pending = [8, -1]
          color_chat_selected = [0, 14]
          color_chat_separator = [8, -1, "i"]
          color_chat_standout = [14, -1]
          color_chat_edited = [8, -1]
          color_chat_url = [14, -1, "u"]
          color_chat_spoiler = [8, -1]
          color_chat_code = [7, 0]

          color_status_line = [0, 2]
          color_extra_line = [0, 12]
          color_title_line = [0, 6]

          color_prompt = [6, -1]
          color_input_line = [-1, -1]
          color_cursor = [0, 6]
          color_misspelled = [3, -1]

          color_tree_default = [-1, -1]
          color_tree_selected = [0, 2]
          color_tree_muted = [8, -1]
          color_tree_active = [2, -1]
          color_tree_unseen = [7, -1, "b"]
          color_tree_mentioned = [1, -1]
          color_tree_active_mentioned = [1, 0]

          color_format_message = [[-1, -1], [8, -2, 0, 0, 7], [6, -2, 0, 8, 9], [6, -2, 0, 19, 20]]
          color_format_reply = [[8, -1], [12, -2, 0, 0, 7], [6, -2, 0, 8, 9], [6, -2, 0, 19, 20], [-1, -2, 0, 21, 27]]
          color_format_reactions = [[8, -1], [5, -2, 0, 0, 7], [-1, -2, 0, 23, 27]]
          color_format_forum = [[-1, -1], [8, -2, 0, 0, 12], [6, -2, 0, 15, 20]]
        '';
      };
    };
  };
}
