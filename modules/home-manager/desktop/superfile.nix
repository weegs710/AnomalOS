{
  config,
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
        version = "1.4.0";
        src = pkgs.fetchFromGitHub {
          owner = "yorukot";
          repo = "superfile";
          rev = "v1.4.0";
          hash = "sha256-famFzCmernwgY70UIhJEbN2ERe4DMuSyf/DbM3e0LQA=";
        };
        vendorHash = "sha256-quobh++hsMbofbjXfquSzMgLtuLP3aLG+fcMnZiZ2Cg=";
        doCheck = false;
      });

      metadataPackage = pkgs.exiftool;
      zoxidePackage = pkgs.zoxide;

      settings = {
        # Theme (required field, but transparent_background will override visual colors)
        theme = "catppuccin";

        # Inherit terminal theme from Noctalia instead of forcing superfile's theme
        transparent_background = true;

        # Editor configuration
        editor = "";
        dir_editor = "";

        # Display options
        show_panel_footer_info = true;
        default_directory = ".";
        file_size_use_si = false;
        file_preview_width = 0;
        sidebar_width = 20;

        # Behavior
        auto_check_update = true;
        cd_on_quit = false;
        shell_close_on_success = false;
        debug = false;
        ignore_missing_fields = false;

        # Code previewer (empty string uses builtin chroma, "bat" for bat)
        code_previewer = "";

        # Plugins
        metadata = true;
        zoxide_support = true;
        enable_md5_checksum = true;

        # Visual
        nerdfont = true;
        default_open_file_preview = true;
        show_image_preview = true;

        # Sorting
        default_sort_type = 0;
        sort_order_reversed = false;
        case_sensitive_sort = false;

        # Border style
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

      hotkeys = { };
    };
  };
}
