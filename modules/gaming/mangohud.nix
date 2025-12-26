{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.gaming {
    home-manager.users.${config.mySystem.user.name} = {
      xdg.configFile."MangoHud/MangoHud.conf".text = ''
        legacy_layout=0
        hud_no_margin
        font_size=24
        text_outline
        position=top-left
      '';

      xdg.configFile."MangoHud/presets.conf".text = ''
        [preset 0]
        no_display

        [preset 1]
        legacy_layout=0
        hud_no_margin
        fps

        [preset 2]
        legacy_layout=0
        hud_no_margin
        horizontal
        gpu_stats
        cpu_stats
        ram
        fps

        [preset 3]
        legacy_layout=0
        hud_no_margin
        gpu_stats
        cpu_stats
        gpu_temp
        cpu_temp
        vram
        ram
        fps
        frametime
        frame_timing
        gpu_power
        cpu_power

        [preset 4]
        legacy_layout=0
        hud_no_margin
        gpu_stats
        cpu_stats
        core_load
        gpu_temp
        cpu_temp
        gpu_core_clock
        gpu_mem_clock
        gpu_power
        cpu_power
        cpu_mhz
        vram
        ram
        fps
        frametime
        frame_timing
        io_read
        io_write
        engine_version
        gpu_name
        vulkan_driver
      '';
    };
  };
}
