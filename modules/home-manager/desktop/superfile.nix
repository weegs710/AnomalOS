{
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.desktop {
    programs.superfile = {
      enable = true;

      package = pkgs.superfile.overrideAttrs (old: {
        version = "1.5.0";
        src = pkgs.fetchFromGitHub {
          owner = "yorukot";
          repo = "superfile";
          rev = "v1.5.0";
          hash = "sha256-PEojifuiIjF3OUxDoMCyynOJUpFglTzh7lJUcq7g4e0=";
        };
        vendorHash = "sha256-5SSnrG3DvD1i7rNcpztHkUUap4Qp7MX04ofD7rA3xgM=";
        doCheck = false;
      });

      metadataPackage = pkgs.exiftool;
      zoxidePackage = pkgs.zoxide;

      settings = {
        theme = "";
        transparent_background = true;
        editor = "";
        dir_editor = "";
        show_panel_footer_info = true;
        default_directory = ".";
        file_size_use_si = false;
        file_preview_width = 0;
        sidebar_width = 20;
        auto_check_update = true;
        cd_on_quit = false;
        shell_close_on_success = false;
        debug = false;
        ignore_missing_fields = false;
        code_previewer = "";
        metadata = true;
        zoxide_support = true;
        enable_md5_checksum = true;
        nerdfont = true;
        default_open_file_preview = true;
        show_image_preview = true;
        default_sort_type = 0;
        sort_order_reversed = false;
        case_sensitive_sort = false;
        border_top = "─";
        border_bottom = "─";
        border_left = "│";
        border_right = "│";
        border_top_left = "╭";
        border_top_right = "╮";
        border_bottom_left = "╰";
        border_bottom_right = "╯";
        border_middle_left = "├";
        border_middle_right = "┤";
      };

      hotkeys = {};
    };
  };
}
