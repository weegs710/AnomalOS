# Wrapped RetroArch with all cores and optimized 1440p configs
# Run with: nix run git+https://codeberg.org/weegs710/AnomalOS#retroarch
{
  perSystem = {pkgs, ...}: let
    # Define all core configurations
    coreConfigs = {
      "Nestopia UE/Nestopia UE.opt" = ''
        nestopia_blargg_ntsc_filter = "composite"
        nestopia_palette = "cxa2025as"
        nestopia_overscan_v = "enabled"
        nestopia_overscan_h = "disabled"
        nestopia_aspect = "auto"
        nestopia_favored_system = "auto"
        nestopia_fds_auto_insert = "enabled"
        nestopia_nospritelimit = "disabled"
        nestopia_audio_vol_dpcm = "100"
        nestopia_audio_vol_sq1 = "100"
        nestopia_audio_vol_sq2 = "100"
        nestopia_audio_vol_tri = "100"
        nestopia_audio_vol_noise = "100"
      '';

      "bsnes/bsnes.opt" = ''
        bsnes_aspect_ratio = "4:3"
        bsnes_ppu_show_overscan = "OFF"
        bsnes_blur_emulation = "OFF"
        bsnes_hotfixes = "OFF"
        bsnes_entropy = "Low"
        bsnes_cpu_overclock = "100"
        bsnes_cpu_fastmath = "OFF"
        bsnes_dsp_fast = "ON"
        bsnes_coprocessor_delayed_sync = "ON"
        bsnes_coprocessor_prefer_hle = "ON"
        bsnes_sgb_bios = "SGB1.sfc"
      '';

      "Mupen64Plus-Next/Mupen64Plus-Next.opt" = ''
        mupen64plus-next-rdp-plugin = "gliden64"
        mupen64plus-next-rsp-plugin = "hle"
        mupen64plus-next-43screensize = "960x720"
        mupen64plus-next-169screensize = "1280x720"
        mupen64plus-next-filtering = "automatic"
        mupen64plus-next-internalresolution = "1440x1080"
        mupen64plus-next-EnableCopyColorToRDRAM = "Async"
        mupen64plus-next-EnableCopyDepthToRDRAM = "Software"
        mupen64plus-next-EnableEnhancedHighResStorage = "True"
        mupen64plus-next-EnableEnhancedTextureStorage = "True"
        mupen64plus-next-EnableFBEmulation = "True"
        mupen64plus-next-EnableFragmentDepthWrite = "True"
        mupen64plus-next-EnableHWLighting = "False"
        mupen64plus-next-EnableLODEmulation = "True"
        mupen64plus-next-EnableN64DepthCompare = "False"
        mupen64plus-next-EnableNativeResFactor = "4"
        mupen64plus-next-EnableTexCoordBounds = "True"
        mupen64plus-next-MaxTxCacheSize = "8000"
        mupen64plus-next-MultiSampling = "0"
        mupen64plus-next-ThreadedRenderer = "True"
        mupen64plus-next-txFilterMode = "None"
        mupen64plus-next-txEnhancementMode = "None"
      '';

      "Gambatte/Gambatte.opt" = ''
        gambatte_gb_colorization = "auto"
        gambatte_gb_internal_palette = "GB - DMG"
        gambatte_gb_palette_pixelshift_1 = "0"
        gambatte_gb_palette_twb64_1 = "TWB64 001"
        gambatte_gbc_color_correction = "accurate"
        gambatte_gbc_color_correction_mode = "accurate"
        gambatte_gbc_frontlight_position = "central"
        gambatte_dark_filter_level = "0"
        gambatte_mix_frames = "disabled"
        gambatte_up_down_allowed = "disabled"
      '';

      "mGBA/mGBA.opt" = ''
        mgba_allow_opposing_directions = "no"
        mgba_audio_low_pass_filter = "disabled"
        mgba_audio_low_pass_range = "60"
        mgba_color_correction = "GBA"
        mgba_force_gbp = "OFF"
        mgba_frameskip = "disabled"
        mgba_frameskip_interval = "0"
        mgba_frameskip_threshold = "33"
        mgba_gb_colors = "Grayscale"
        mgba_gb_model = "Autodetect"
        mgba_idle_optimization = "Remove Known"
        mgba_interframe_blending = "smart"
        mgba_sgb_borders = "ON"
        mgba_skip_bios = "OFF"
        mgba_use_bios = "ON"
      '';

      "melonDS/melonDS.opt" = ''
        melonds_console_mode = "DS"
        melonds_boot_directly = "enabled"
        melonds_screen_layout = "Top/Bottom"
        melonds_screen_gap = "0"
        melonds_hybrid_small_screen = "Bottom"
        melonds_touch_mode = "Mouse"
        melonds_use_dsi_bios = "disabled"
        melonds_render_mode = "software"
        melonds_threaded_renderer = "enabled"
        melonds_jit_enable = "enabled"
        melonds_jit_block_size = "32"
        melonds_jit_branch_optimisations = "enabled"
        melonds_jit_literal_optimisations = "enabled"
        melonds_jit_fast_memory = "enabled"
        melonds_sram_save_interval = "disabled"
      '';

      "Genesis Plus GX/Genesis Plus GX.opt" = ''
        genesis_plus_gx_addr_error = "enabled"
        genesis_plus_gx_aspect_ratio = "auto"
        genesis_plus_gx_audio_filter = "disabled"
        genesis_plus_gx_bios = "disabled"
        genesis_plus_gx_blargg_ntsc_filter = "disabled"
        genesis_plus_gx_cd_latency = "disabled"
        genesis_plus_gx_frameskip = "disabled"
        genesis_plus_gx_gun_cursor = "disabled"
        genesis_plus_gx_invert_mouse = "disabled"
        genesis_plus_gx_lcd_filter = "disabled"
        genesis_plus_gx_overscan = "disabled"
        genesis_plus_gx_remove_per_line_sprite_limit = "disabled"
        genesis_plus_gx_render = "single field"
        genesis_plus_gx_sound_output = "stereo"
        genesis_plus_gx_ym2413 = "auto"
        genesis_plus_gx_ym2612 = "mame (ym2612)"
      '';

      "Beetle Saturn/Beetle Saturn.opt" = ''
        beetle_saturn_analog_stick_deadzone = "15%"
        beetle_saturn_cart = "Auto Detect"
        beetle_saturn_cdimagecache = "disabled"
        beetle_saturn_horizontal_blend = "disabled"
        beetle_saturn_horizontal_overscan = "0"
        beetle_saturn_initial_scanline = "0"
        beetle_saturn_initial_scanline_pal = "0"
        beetle_saturn_last_scanline = "239"
        beetle_saturn_last_scanline_pal = "287"
        beetle_saturn_midsync = "disabled"
        beetle_saturn_mouse_sensitivity = "100%"
        beetle_saturn_multitap_port1 = "disabled"
        beetle_saturn_multitap_port2 = "disabled"
        beetle_saturn_region = "Auto Detect"
        beetle_saturn_virtuagun_crosshair = "White"
      '';

      "Flycast/Flycast.opt" = ''
        reicast_alpha_sorting = "per-strip (fast)"
        reicast_analog_stick_deadzone = "15%"
        reicast_anisotropic_filtering = "16"
        reicast_boot_to_bios = "disabled"
        reicast_broadcast = "NTSC"
        reicast_cable_type = "VGA (RGB)"
        reicast_custom_textures = "disabled"
        reicast_div_matching = "auto"
        reicast_enable_dsp = "disabled"
        reicast_framerate = "fullspeed"
        reicast_gdrom_fast_loading = "disabled"
        reicast_internal_resolution = "1440x1080"
        reicast_mipmapping = "enabled"
        reicast_oit_abuffer_size = "512MB"
        reicast_per_content_vmus = "VMU A1"
        reicast_pvr2_filtering = "trilinear"
        reicast_region = "USA"
        reicast_render_to_texture_upscaling = "1x"
        reicast_screen_rotation = "horizontal"
        reicast_synchronous_rendering = "enabled"
        reicast_texupscale = "off"
        reicast_threaded_rendering = "enabled"
        reicast_trigger_deadzone = "0%"
        reicast_widescreen_hack = "disabled"
      '';

      "Beetle PSX HW/Beetle PSX HW.opt" = ''
        beetle_psx_hw_adaptive_smoothing = "disabled"
        beetle_psx_hw_analog_calibration = "disabled"
        beetle_psx_hw_analog_toggle = "disabled"
        beetle_psx_hw_cd_access_method = "sync"
        beetle_psx_hw_cd_fastload = "2x(native)"
        beetle_psx_hw_crop_overscan = "enabled"
        beetle_psx_hw_depth = "32bpp"
        beetle_psx_hw_dither_mode = "internal resolution"
        beetle_psx_hw_display_internal_fps = "disabled"
        beetle_psx_hw_dualshock_analog_button_toggle = "disabled"
        beetle_psx_hw_enable_memcard1 = "enabled"
        beetle_psx_hw_enable_multitap_port1 = "disabled"
        beetle_psx_hw_enable_multitap_port2 = "disabled"
        beetle_psx_hw_filter = "nearest"
        beetle_psx_hw_gte_overclock = "disabled"
        beetle_psx_hw_gpu_overclock = "1x(native)"
        beetle_psx_hw_image_crop = "disabled"
        beetle_psx_hw_image_offset = "disabled"
        beetle_psx_hw_initial_scanline = "0"
        beetle_psx_hw_initial_scanline_pal = "0"
        beetle_psx_hw_internal_resolution = "4x"
        beetle_psx_hw_last_scanline = "239"
        beetle_psx_hw_last_scanline_pal = "287"
        beetle_psx_hw_mdec_yuv = "disabled"
        beetle_psx_hw_memcard_left_index = "0"
        beetle_psx_hw_memcard_right_index = "1"
        beetle_psx_hw_msaa = "1x"
        beetle_psx_hw_pal_video_timing_override = "disabled"
        beetle_psx_hw_pgxp_2d_tol = "0px"
        beetle_psx_hw_pgxp_mode = "memory only"
        beetle_psx_hw_pgxp_nclip = "disabled"
        beetle_psx_hw_pgxp_preserve_proj_fp = "disabled"
        beetle_psx_hw_pgxp_texture = "enabled"
        beetle_psx_hw_pgxp_vertex = "enabled"
        beetle_psx_hw_renderer = "hardware"
        beetle_psx_hw_renderer_software_fb = "enabled"
        beetle_psx_hw_scale_dither = "disabled"
        beetle_psx_hw_shared_memory_cards = "disabled"
        beetle_psx_hw_skip_bios = "disabled"
        beetle_psx_hw_super_sampling = "disabled"
        beetle_psx_hw_widescreen_hack = "disabled"
        beetle_psx_hw_wireframe = "disabled"
      '';

      "PCSX2/PCSX2.opt" = ''
        pcsx2_afk_hack = "disabled"
        pcsx2_align_sprite_hack = "disabled"
        pcsx2_auto_flush_sw = "disabled"
        pcsx2_bilinear_filtering = "bilinear (smooth)"
        pcsx2_boot_mode = "fast"
        pcsx2_cpu_overclock = "1.0"
        pcsx2_enable_cheats = "disabled"
        pcsx2_enable_extra_memory = "disabled"
        pcsx2_enable_host_fs = "disabled"
        pcsx2_enable_patches = "disabled"
        pcsx2_fast_cdvd = "disabled"
        pcsx2_framerate = "auto"
        pcsx2_fxaa = "disabled"
        pcsx2_half_pixel_offset_hack = "disabled"
        pcsx2_interlacing = "auto"
        pcsx2_merge_sprite_hack = "disabled"
        pcsx2_mipmapping = "enabled"
        pcsx2_pal_video_timing = "disabled"
        pcsx2_preload_textures = "disabled"
        pcsx2_renderer = "Auto"
        pcsx2_round_sprite_hack = "disabled"
        pcsx2_skipdraw_end = "0"
        pcsx2_skipdraw_start = "0"
        pcsx2_tc_offset_x = "0"
        pcsx2_tc_offset_y = "0"
        pcsx2_texture_filtering = "Bilinear (PS2)"
        pcsx2_texture_inside_rt = "disabled"
        pcsx2_trilinear_filtering = "automatic"
        pcsx2_upscale_multiplier = "4"
        pcsx2_wild_arms_hack = "disabled"
      '';

      "PPSSPP/PPSSPP.opt" = ''
        ppsspp_analog_deadzone = "0.0"
        ppsspp_analog_is_circular = "disabled"
        ppsspp_analog_sensitivity = "1.00"
        ppsspp_auto_frameskip = "disabled"
        ppsspp_backend = "vulkan"
        ppsspp_button_preference = "Cross"
        ppsspp_cache_iso = "enabled"
        ppsspp_cheats = "disabled"
        ppsspp_cpu_core = "JIT"
        ppsspp_cropto16x9 = "disabled"
        ppsspp_detect_vsync_swap_interval = "disabled"
        ppsspp_disable_range_culling = "disabled"
        ppsspp_enable_wlan = "disabled"
        ppsspp_fast_memory = "enabled"
        ppsspp_force_lag_sync = "enabled"
        ppsspp_frame_duplication = "enabled"
        ppsspp_frameskip = "disabled"
        ppsspp_frameskiptype = "Number of frames"
        ppsspp_gpu_hardware_transform = "enabled"
        ppsspp_hardware_tesselation = "disabled"
        ppsspp_ignore_bad_memory_access = "enabled"
        ppsspp_inflight_frames = "Up to 2"
        ppsspp_internal_resolution = "1920x1088"
        ppsspp_io_timing_method = "Fast"
        ppsspp_language = "Automatic"
        ppsspp_lazy_texture_caching = "disabled"
        ppsspp_locked_cpu_speed = "disabled"
        ppsspp_lower_resolution_for_effects = "disabled"
        ppsspp_memstick_inserted = "enabled"
        ppsspp_mulitsample_level = "Disabled"
        ppsspp_psp_model = "psp_2000_3000"
        ppsspp_skip_buffer_effects = "disabled"
        ppsspp_skip_gpu_readbacks = "disabled"
        ppsspp_smart_2d_texture_filtering = "disabled"
        ppsspp_software_rendering = "disabled"
        ppsspp_software_skinning = "enabled"
        ppsspp_spline_quality = "High"
        ppsspp_texture_anisotropic_filtering = "16x"
        ppsspp_texture_deposterize = "enabled"
        ppsspp_texture_filtering = "Linear"
        ppsspp_texture_replacement = "disabled"
        ppsspp_texture_scaling_level = "4x"
        ppsspp_texture_scaling_type = "hybrid"
        ppsspp_texture_shader = "disabled"
      '';

      "Stella/Stella.opt" = ''
        stella_console = "auto"
        stella_filter = "disabled"
        stella_mix_frames = "disabled"
        stella_ntsc_aspect = "par"
        stella_palette = "standard"
        stella_phosphor = "auto"
        stella_stelladaptor_1 = "auto"
        stella_stelladaptor_2 = "auto"
      '';

      "Beetle PCE Fast/Beetle PCE Fast.opt" = ''
        pce_fast_Turbo_Delay = "Fast"
        pce_fast_Turbo_Toggling = "disabled"
        pce_fast_adpcmvolume = "100"
        pce_fast_arcade_card = "enabled"
        pce_fast_cdbios = "System Card 3"
        pce_fast_cdpsgvolume = "100"
        pce_fast_cdspeed = "1"
        pce_fast_cdimagecache = "disabled"
        pce_fast_disable_softreset = "disabled"
        pce_fast_hoverscan = "300"
        pce_fast_initial_scanline = "3"
        pce_fast_last_scanline = "242"
        pce_fast_mouse_sensitivity = "1.00"
        pce_fast_no_sprite_limit = "enabled"
        pce_fast_ocmultiplier = "1"
        pce_fast_turbo_toggling = "disabled"
      '';
    };

    # Build config directory with all core configs
    configDir = pkgs.runCommand "retroarch-config" {} ''
      mkdir -p $out/config
      ${pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: content: ''
          mkdir -p "$out/config/$(dirname "${name}")"
          cat > "$out/config/${name}" << 'EOF'
          ${content}
          EOF
        '')
        coreConfigs)}
    '';

    # Wrap RetroArch with all cores (using unfree-enabled pkgs for genesis-plus-gx)
    baseRetroArch = pkgs.wrapRetroArch {
      cores = with pkgs.libretro; [
        nestopia
        bsnes
        mupen64plus
        gambatte
        mgba
        melonds
        genesis-plus-gx
        picodrive
        beetle-saturn
        flycast
        beetle-psx-hw
        pcsx2
        ppsspp
        stella
        beetle-pce-fast
        atari800
        prosystem
        handy
        virtualjaguar
        hatari
        beetle-vb
        gw
        beetle-ngp
        beetle-wswan
        bluemsx
        vice-x64
        vice-xplus4
        vice-xvic
        puae
        freeintv
        vecx
        o2em
        np2kai
        fuse
      ];
    };

    wrappedRetroArch = pkgs.symlinkJoin {
      name = "retroarch-wrapped";
      paths = [baseRetroArch];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/retroarch \
          --set-default XDG_CONFIG_HOME "$HOME/.config" \
          --run "mkdir -p \$HOME/.config/retroarch/config" \
          --run "cp -r ${configDir}/config/* \$HOME/.config/retroarch/config/ || true"
      '';
      meta.mainProgram = "retroarch";
    };
  in {
    packages.retroarch = wrappedRetroArch;
  };
}
