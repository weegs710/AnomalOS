{
  flake.nixosModules.hyprland-system = {
    config,
    pkgs,
    ...
  }: {
    programs = {
      hyprland = {
        enable = true;
        xwayland.enable = true;
      };
    };

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-termfilechooser
      ];
      configPackages = [pkgs.hyprland];
      config = {
        Hyprland = {
          default = [
            "gtk"
            "hyprland"
          ];
          "org.freedesktop.impl.portal.FileChooser" = ["termfilechooser" "gtk"];
          "org.freedesktop.impl.portal.ScreenCast" = ["hyprland"];
          "org.freedesktop.impl.portal.Screenshot" = ["hyprland"];
        };
      };
    };

    services = {
      hypridle.enable = true;
      xserver.enable = false;
    };

    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      grim
      hyprshot
      slurp
      wl-clipboard
      wl-clip-persist
    ];

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      # GTK3 apps bypass xdg-portal for file dialogs without this
      GTK_USE_PORTAL = "1";
    };
  };
}
