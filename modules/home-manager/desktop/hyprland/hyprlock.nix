{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.desktop {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        grace = 0;
      };

      background = [
        {
          path = "/home/${osConfig.mySystem.user.name}/.cache/hyprlock-wallpaper";
        }
      ];

      input-field = [
        {
          size = "250, 50";
          outline_thickness = 2;
          dots_size = 0.2;
          dots_spacing = 0.35;
          dots_center = true;
          outer_color = "rgb(${osConfig.lib.stylix.colors.base04})";
          inner_color = "rgba(${osConfig.lib.stylix.colors.base00}BF)";
          font_color = "rgb(${osConfig.lib.stylix.colors.base04})";
          fade_on_empty = false;
          placeholder_text = "<span foreground='##${osConfig.lib.stylix.colors.base04}'>Enter Password...</span>";
          hide_input = false;
          position = "0, -100";
          halign = "center";
          valign = "center";
        }
      ];

      shape = [
        {
          size = "350, 120";
          color = "rgba(${osConfig.lib.stylix.colors.base00}BF)";
          rounding = 60;
          border_size = 0;
          position = "0, 150";
          halign = "center";
          valign = "center";
        }
        {
          size = "350, 50";
          color = "rgba(${osConfig.lib.stylix.colors.base00}BF)";
          rounding = 25;
          border_size = 0;
          position = "0, 50";
          halign = "center";
          valign = "center";
        }
      ];

      label = [
        {
          text = ''cmd[update:1000] echo "$(date +"%-I:%M")"'';
          color = "rgb(${osConfig.lib.stylix.colors.base05})";
          font_size = 95;
          font_family = "Terminess Nerd Font";
          position = "0, 150";
          halign = "center";
          valign = "center";
        }
        {
          text = ''cmd[update:60000] echo "$(date +"%A, %B %d")"'';
          color = "rgb(${osConfig.lib.stylix.colors.base04})";
          font_size = 22;
          font_family = "Terminess Nerd Font";
          position = "0, 50";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
  };
}
