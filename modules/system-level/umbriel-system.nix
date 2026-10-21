{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.umbriel.nixosModules.default ];

  hardware.graphics.enable = true;

  programs.umbriel.enable = true;
  # The HKC drops HDMI hotplug detect ~11s into dpms-off, and the rebuilt output would otherwise power straight back on.
  programs.umbriel.package =
    inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [ ./umbriel-dpms-reconnect-hold-patch ];
      });

  xdg.portal = {
    enable = true;
    # OpenURI only honours a default for web schemes and inode/directory, so routing xdg-open through it shows an app chooser for every other type regardless of mimeapps
    xdgOpenUsePortal = false;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-termfilechooser
    ];
    # Section key is the runtime XDG_CURRENT_DESKTOP, which the compositor setenvs lowercase.
    config.umbriel = {
      default = [
        "umbriel"
        "gtk"
      ];
      "org.freedesktop.impl.portal.FileChooser" = [
        "termfilechooser"
        "gtk"
      ];
    };
  };

  services = {
    xserver.enable = false;

    # Umbriel rejects bare mouse binds and names only 5 buttons, so the ball's extra buttons are remapped below evdev.
    keyd = {
      enable = true;
      keyboards.trackball = {
        ids = [ "056e:011c" ];
        settings.main = {
          mouse1 = "f13";
          mouse2 = "f14";
          mouseforward = "f15";
          mouseback = "f16";
          f18 = "f17";
          # Tilts stay real pointer buttons so the focused app gets browser back/forward, not a compositor action.
          scrollleft = "mouse1";
          scrollright = "mouse2";
        };
      };
    };
  };

  users.users.${config.mySystem.user.name}.packages = with pkgs; [
    wl-clipboard
    grim
    satty
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    # GTK3 apps bypass xdg-portal for file dialogs without this
    GTK_USE_PORTAL = "1";
  };
}
