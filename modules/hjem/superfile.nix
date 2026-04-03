{...}: {
  flake.nixosModules.superfileUser = {
    config,
    lib,
    ...
  }: let
    username = config.mySystem.user.name;
  in {
    config = lib.mkIf config.mySystem.features.desktop {
      hjem.users.${username}.xdg.config.files."superfile/config.toml".text = ''
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
        dir_editor = "fresh"
        editor = "fresh"
        enable_md5_checksum = true
        enable_file_preview_border = true
        file_panel_extra_columns = 2
        file_panel_name_percent = 50
        file_preview_width = 3
        file_size_use_si = false
        ignore_missing_fields = false
        metadata = true
        nerdfont = true
        page_scroll_size = 10
        shell_close_on_success = false
        show_image_preview = true
        show_panel_footer_info = true
        show_select_icons = true
        sidebar_width = 20
        sort_order_reversed = false
        theme = ""
        transparent_background = true
        zoxide_support = true

        [open_with]
        apng = "qview"
        avif = "qview"
        bmp = "qview"
        exr = "qview"
        gif = "qview"
        hdr = "qview"
        heic = "qview"
        heif = "qview"
        ico = "qview"
        jpeg = "qview"
        jpg = "qview"
        jxl = "qview"
        kra = "qview"
        ora = "qview"
        pbm = "qview"
        pcx = "qview"
        pgm = "qview"
        png = "qview"
        ppm = "qview"
        psd = "qview"
        sgi = "qview"
        svg = "qview"
        tga = "qview"
        tif = "qview"
        tiff = "qview"
        webp = "qview"
        xbm = "qview"
        xcf = "qview"
        xpm = "qview"
        3gp = "xdg-open"
        avi = "xdg-open"
        flv = "xdg-open"
        m2ts = "xdg-open"
        m4v = "xdg-open"
        mkv = "xdg-open"
        mov = "xdg-open"
        mp4 = "xdg-open"
        mpeg = "xdg-open"
        mpg = "xdg-open"
        mts = "xdg-open"
        ogv = "xdg-open"
        ts = "xdg-open"
        vob = "xdg-open"
        webm = "xdg-open"
        wmv = "xdg-open"
        aac = "euphonica"
        aiff = "euphonica"
        ape = "euphonica"
        flac = "euphonica"
        m4a = "euphonica"
        mp3 = "euphonica"
        ogg = "euphonica"
        opus = "euphonica"
        wav = "euphonica"
        wma = "euphonica"
        pdf = "zathura"
        7z = "file-roller"
        bz2 = "file-roller"
        gz = "file-roller"
        rar = "file-roller"
        tar = "file-roller"
        xz = "file-roller"
        zip = "file-roller"
        zst = "file-roller"
        htm = "zen"
        html = "zen"
        torrent = "transmission-gtk"
      '';
    };
  };
}
