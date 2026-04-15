{
  flake.nixosModules.desktop-services = {...}: {
    services = {
      displayManager = {
        defaultSession = "hyprland";
        ly = {
          enable = true;
          settings = {
            clock = "%-I:%M %p  %a, %d %b %Y";
            save = true;
            show_tty = true;
            hide_borders = true;
            animation = "matrix";
            animation_frame_delay = 1;
            cmatrix_fg = "0x0040E0FF";
            cmatrix_head_col = "0x01B060FF";
          };
        };
      };
      blueman.enable = true;
      upower.enable = true;
      ratbagd.enable = true;
      udisks2.enable = true;
      gvfs.enable = true;
      locate.enable = true;
      speechd.enable = false;
    };

    programs = {
      partition-manager.enable = true;
    };
  };
}
