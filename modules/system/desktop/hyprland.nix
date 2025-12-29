{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.desktop {
    programs = {
      hyprland = {
        enable = true;
        xwayland.enable = true;
      };
      waybar.enable = false;
    };

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
      configPackages = [pkgs.hyprland];
      config = {
        Hyprland = {
          default = [
            "gtk"
            "hyprland"
          ];
          "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
          "org.freedesktop.impl.portal.ScreenCast" = ["hyprland"];
          "org.freedesktop.impl.portal.Screenshot" = ["hyprland"];
        };
      };
    };

    security.pam.services.hyprlock = {};

    systemd.user.services.xdg-desktop-portal.environment = {
      XDG_DESKTOP_PORTAL_DIR = "/run/current-system/sw/share/xdg-desktop-portal/portals";
    };

    services = {
      hypridle.enable = true;
      xserver.enable = false;
    };

    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      grim
      hyprshot
      slurp
      swww
      wl-clipboard
      wl-clip-persist
      wlogout
      wlsunset
    ];

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

  };
}
