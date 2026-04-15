{
  flake.nixosModules.ly = {...}: {
    services.displayManager = {
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
  };
}
