{inputs, ...}: {
  flake.nixosModules.superfile = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    wrappedSuperfile = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.superfile;
  in
    with lib; {
      config = mkIf config.mySystem.features.desktop {
        users.users.${username}.packages = [ wrappedSuperfile ];

        hjem.users.${username} = {
          xdg.config.files."superfile/config.toml".text = ''
            auto_check_update = true
            border_bottom = "─"
            border_bottom_left = "╰"
            border_bottom_right = "╯"
            border_left = "│"
            border_middle_left = "├"
            border_middle_right = "┤"
            border_right = "│"
            border_top = "─"
            border_top_left = "╭"
            border_top_right = "╮"
            case_sensitive_sort = false
            cd_on_quit = false
            code_previewer = ""
            debug = false
            default_directory = "."
            default_open_file_preview = true
            default_sort_type = 0
            dir_editor = ""
            editor = ""
            enable_md5_checksum = true
            file_preview_width = 0
            file_size_use_si = false
            ignore_missing_fields = false
            metadata = true
            nerdfont = true
            shell_close_on_success = false
            show_image_preview = true
            show_panel_footer_info = true
            sidebar_width = 20
            sort_order_reversed = false
            theme = ""
            transparent_background = true
            zoxide_support = true
          '';
        };
      };
    };
}
