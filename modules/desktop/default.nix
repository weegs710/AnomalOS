# Desktop environment configuration
# Wayland-based desktop with Hyprland compositor, SDDM, and PipeWire audio
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [
    ./hyprland.nix
    ./stylix.nix
    ./media.nix
  ];

  config = mkIf config.mySystem.features.desktop {
    # Basic desktop services
    services = {
      displayManager = {
        autoLogin.enable = false;
        defaultSession = "hyprland";
        sddm = {
          enable = true;
          wayland.enable = true;
        };
      };

      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = config.services.pipewire.enable;
      };

      upower.enable = true;
      ratbagd.enable = true;
      devmon.enable = true;
      locate.enable = true;
    };

    security.pam.services.sddm.kwallet.enable = true;

    # XDG portal setup
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };

    programs = {
      file-roller.enable = true;
      thunar.enable = true;
      udevil.enable = true;
    };

    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      # Applications
      pavucontrol
      qalculate-gtk
      qview
      transmission_4-gtk
      unzipNLS
      vlc
      zathura

      # Utilities
      alarm-clock-applet
      bluetui
      fastfetch
      gparted
      piper

      # System libraries and support
      adwaita-icon-theme
      dbus
      dbus-broker
      kdePackages.kwallet
      kdePackages.kwallet-pam
      kdePackages.kwalletmanager
      libGL
      libnotify
      libportal
      lm_sensors
      mesa
      wireplumber
      xdg-dbus-proxy
      xfce.thunar-volman

      # Terminal and system utilities
      cliphist
      dunst
      pamixer
      rofi
      ueberzugpp

      # X11 compatibility libraries
      xorg.libX11
      xorg.libXcursor
      xorg.libXi
      xorg.libXinerama
      xorg.libXrandr
      xorg.libXxf86vm
    ];

    # Desktop utility aliases
    environment.shellAliases = {
      gparted = "sudo WAYLAND_DISPLAY=$WAYLAND_DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR gparted";
    };

    home-manager.users.${config.mySystem.user.name} = {
      services.dunst.enable = true;
      stylix.targets.dunst.enable = true;

      programs.hyprlock = {
        enable = true;
        settings = {
          general = {
            no_fade_in = false;
            grace = 0;
            disable_loading_bar = false;
          };

          image = [
            {
              monitor = "";
              path = "\${HOME}/Pictures/monster.jpg";
              border_size = 2;
              border_color = "rgb(${config.lib.stylix.colors.base0C})";
              size = 300;
              rounding = 270;
              position = "25, 0";
              halign = "center";
              valign = "center";
            }
          ];

          label = [
            {
              monitor = "";
              text = "cmd[update:1000] echo -e \"<b>\$(date +\"%A, %B %d\")</b>\"";
              color = "rgb(${config.lib.stylix.colors.base09})";
              font_size = 32;
              font_family = "Iosevka Nerd Font";
              position = "0, -110";
              halign = "center";
              valign = "top";
            }
            {
              monitor = "";
              text = "cmd[update:1000] echo \"<span>\$(date +\"%X\")</span>\"";
              color = "rgb(${config.lib.stylix.colors.base09})";
              font_size = 42;
              font_family = "Iosevka Nerd Font";
              position = "0, -150";
              halign = "center";
              valign = "top";
            }
            {
              monitor = "";
              text = "   \$USER";
              color = "rgb(${config.lib.stylix.colors.base0E})";
              outline_thickness = 2;
              font_size = 20;
              font_family = "Iosevka Nerd Font";
              position = "0, 157";
              halign = "center";
              valign = "bottom";
            }
          ];

          shape = [
            {
              monitor = "";
              size = "320, 55";
              color = "rgb(${config.lib.stylix.colors.base00})";
              rounding = -1;
              border_size = 2;
              border_color = "rgb(${config.lib.stylix.colors.base0C})";
              position = "0, 140";
              halign = "center";
              valign = "bottom";
            }
          ];

          input-field = lib.mkForce [
            {
              monitor = "";
              size = "320, 55";
              outline_thickness = 2;
              dots_size = 0.2;
              dots_spacing = 0.2;
              dots_center = true;
              outer_color = "rgb(${config.lib.stylix.colors.base0C})";
              inner_color = "rgb(${config.lib.stylix.colors.base00})";
              font_color = "rgb(${config.lib.stylix.colors.base0E})";
              fade_on_empty = false;
              font_family = "Iosevka Nerd Font";
              placeholder_text = "<span foreground=\"##${config.lib.stylix.colors.base0C}\">    </span>";
              hide_input = false;
              position = "0, -450";
              halign = "center";
              valign = "center";
            }
          ];
        };
      };
      stylix.targets.hyprlock.enable = true;

      programs.kitty = {
        enable = true;
        font = {
          name = lib.mkForce "Terminess Nerd Font";
          size = lib.mkForce 14;
        };
      };
      stylix.targets.kitty.enable = true;

      programs.yazi = {
        enable = true;
        enableFishIntegration = true;
        keymap = builtins.fromTOML (builtins.readFile ./yazi/keymap.toml);
        settings = builtins.fromTOML (builtins.readFile ./yazi/yazi.toml);
        # Override Stylix theme background
        theme = {
          mgr = {
            bg = lib.mkForce "#${config.lib.stylix.colors.base00}";
          };
          status = {
            separator_open = lib.mkForce "";
            separator_close = lib.mkForce "";
            separator_style = lib.mkForce { fg = "#${config.lib.stylix.colors.base00}"; bg = "#${config.lib.stylix.colors.base00}"; };
          };
          which = {
            mask = { bg = lib.mkForce "#${config.lib.stylix.colors.base00}"; };
          };
        };
      };
      stylix.targets.yazi.enable = true;
      stylix.targets.vesktop.enable = true;

      programs.vesktop.enable = true;

      # Override Yazi desktop file to launch via kitty
      xdg.dataFile."applications/yazi.desktop".text = ''
        [Desktop Entry]
        Name=Yazi
        Icon=yazi
        Comment=Blazing fast terminal file manager written in Rust, based on async I/O
        Exec=kitty -e yazi %u
        Terminal=false
        Type=Application
        MimeType=inode/directory
        Categories=Utility;Core;System;FileTools;FileManager;ConsoleOnly;
        Keywords=File;Manager;Explorer;Browser;Launcher;
      '';

      # Fastfetch configuration
      xdg.configFile."fastfetch/config.jsonc".text = builtins.toJSON {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
        logo = {
          source = "~/dotfiles/modules/desktop/AnomLogo.png";
          height = 20;
          width = 40;
        };
        modules = [
          "title"
          "separator"
          "os"
          "host"
          "kernel"
          "uptime"
          "packages"
          "shell"
          "display"
          "wm"
          "terminal"
          "cpu"
          "gpu"
          "memory"
          "swap"
          "disk"
          "break"
          "colors"
        ];
      };
    };

    # Desktop fonts
    fonts.packages = with pkgs.nerd-fonts; [
      dejavu-sans-mono
      zed-mono
      jetbrains-mono
      fira-code
      terminess-ttf
      space-mono
      hack
      iosevka
    ];
  };
}
