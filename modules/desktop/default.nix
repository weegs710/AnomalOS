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
    ./rofi.nix
    ./flatpak.nix
    ./kdeconnect.nix
    ./autotrash.nix
    ./brave.nix
    # ./stylix-web16.nix
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

    # KWallet PAM integration (SDDM delegates to login stack)
    security.pam.services.login.kwallet = {
      enable = true;
      package = pkgs.kdePackages.kwallet-pam;
    };

    # XDG portal setup
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };

    programs = {
      partition-manager.enable = true;
      udevil.enable = true;
    };

    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      # Applications
      file-roller
      gemini-cli
      kdePackages.okular
      pavucontrol
      qalculate-gtk
      qview
      transmission_4-gtk
      unzipNLS
      vlc

      # Utilities
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

      # Terminal and system utilities
      cliphist
      pamixer
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
      services.swaync = {
        enable = true;
        settings = {
          positionX = "right";
          positionY = "top";
          control-center-margin-top = 10;
          control-center-margin-bottom = 10;
          control-center-margin-right = 10;
          control-center-margin-left = 10;
          timeout = 5;
          timeout-low = 3;
          timeout-critical = 0;
          fit-to-screen = false;
          keyboard-shortcuts = true;
          image-visibility = "when-available";
          transition-time = 200;
        };
      };

      stylix.targets.swaync.enable = true;

      services.swaync.style = ''
        * {
          font-family: "DejaVu Sans";
          font-size: 11pt;
        }

        .notification-row {
          margin: 8px;
        }

        .notification {
          background: @base00;
          border: 2px solid @base0D;
          border-radius: 12px;
          padding: 12px;
          margin: 8px;
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
        }

        .notification.low {
          border: 2px solid @base03;
        }

        .notification.critical {
          border: 2px solid @base08;
          box-shadow: 0 4px 12px rgba(255, 0, 102, 0.3);
        }

        .notification-content {
          background: transparent;
          padding: 8px;
          border: none;
        }

        .summary {
          color: @base05;
          font-weight: bold;
          font-size: 12pt;
          margin-bottom: 4px;
        }

        .body {
          color: @base06;
          font-size: 10pt;
          margin-top: 4px;
        }

        .time {
          color: @base04;
          font-size: 9pt;
          margin-top: 4px;
        }

        .close-button {
          background: @base08;
          color: @base00;
          border-radius: 8px;
          padding: 4px;
          margin: 4px;
          border: none;
        }

        .close-button:hover {
          background: lighter(@base08);
        }

        .notification-action {
          background: @base01;
          color: @base05;
          border: 1px solid @base0D;
          border-radius: 8px;
          padding: 8px;
          margin: 4px;
        }

        .notification-action:hover {
          background: @base02;
        }

        .notification-action:active {
          background: @base0F;
        }

        .control-center {
          background: @base00;
          border: 2px solid @base0D;
          border-radius: 12px;
          padding: 12px;
          margin: 10px;
          box-shadow: 0 4px 16px rgba(0, 0, 0, 0.6);
        }

        .widget-title {
          color: @base05;
          font-size: 14pt;
          font-weight: bold;
          margin: 8px;
        }

        .widget-title > button {
          background: @base01;
          border: 1px solid @base0D;
          border-radius: 8px;
          color: @base05;
          padding: 6px 12px;
        }

        .widget-title > button:hover {
          background: @base02;
        }

        .widget-dnd {
          margin: 8px;
        }

        .widget-dnd > switch {
          background: @base01;
          border: 1px solid @base0D;
          border-radius: 16px;
        }

        .widget-dnd > switch:checked {
          background: @base0B;
        }

        .widget-dnd > switch slider {
          background: @base06;
          border-radius: 12px;
        }
      '';

      stylix.targets.hyprlock.enable = false;

      programs.ghostty = {
        enable = true;
        settings = {
          font-family = "Terminess Nerd Font";
          font-size = 13;
          copy-on-select = "clipboard";
          window-show-tab-bar = "never";
          keybind = [
            "shift+enter=text:\\n"
            "ctrl+v=paste_from_clipboard"
          ];
        };
      };
      stylix.targets.ghostty.enable = true;

      xdg.dataFile."applications/com.mitchellh.ghostty.desktop".text = ''
        [Desktop Entry]
        Name=Ghostty
        Comment=Fast, feature-rich terminal emulator
        Keywords=shell;prompt;command;commandline;cmd;
        Icon=com.mitchellh.ghostty
        StartupWMClass=com.mitchellh.ghostty
        TryExec=ghostty
        Exec=ghostty
        Type=Application
        Categories=System;TerminalEmulator;Utility;
        Terminal=false
      '';

      programs.yazi = {
        enable = true;
        enableFishIntegration = true;
        keymap = builtins.fromTOML (builtins.readFile ./yazi/keymap.toml);
        settings = builtins.fromTOML (builtins.readFile ./yazi/yazi.toml);

        plugins = {
          mount =
            pkgs.fetchFromGitHub {
              owner = "yazi-rs";
              repo = "plugins";
              rev = "19dc890e33b8922eb1a3a165e685436ec4ac0a59";
              sha256 = "sha256-Hml7n07G6tEOPUPOFN9jf01C5LtZRO8pfERVHKHJQRo=";
            }
            + "/mount.yazi";
          git =
            pkgs.fetchFromGitHub {
              owner = "yazi-rs";
              repo = "plugins";
              rev = "19dc890e33b8922eb1a3a165e685436ec4ac0a59";
              sha256 = "sha256-Hml7n07G6tEOPUPOFN9jf01C5LtZRO8pfERVHKHJQRo=";
            }
            + "/git.yazi";
        };

        initLua = ''
          require("git"):setup()
        '';

        # Override Stylix theme background
        theme = {
          mgr = {
            bg = lib.mkForce "#${config.lib.stylix.colors.base00}";
          };
          status = {
            separator_open = lib.mkForce "";
            separator_close = lib.mkForce "";
            separator_style = lib.mkForce {
              fg = "#${config.lib.stylix.colors.base00}";
              bg = "#${config.lib.stylix.colors.base00}";
            };
          };
          which = {
            mask = {
              bg = lib.mkForce "#${config.lib.stylix.colors.base00}";
            };
          };
        };
      };
      stylix.targets.yazi.enable = true;
      stylix.targets.vesktop.enable = true;

      programs.vesktop.enable = true;

      # XDG MIME type associations
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "application/pdf" = "org.kde.okular.desktop";
        };
      };

      xdg.dataFile."pixmaps/yazi.png".source = "${pkgs.yazi}/share/pixmaps/yazi.png";

      xdg.dataFile."applications/yazi.desktop".text = ''
        [Desktop Entry]
        Name=Yazi
        Icon=/home/${config.mySystem.user.name}/.local/share/pixmaps/yazi.png
        Comment=Blazing fast terminal file manager written in Rust, based on async I/O
        Exec=ghostty -e yazi %u
        Terminal=false
        Type=Application
        MimeType=inode/directory
        Categories=Utility;Core;System;FileTools;FileManager;ConsoleOnly;
        Keywords=File;Manager;Explorer;Browser;Launcher;
      '';

      xdg.dataFile."applications/btop.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Version=1.0
        Name=btop++
        GenericName=System Monitor
        Comment=Resource monitor that shows usage and stats for processor, memory, disks, network and processes
        Icon=btop
        Exec=hyprctl dispatch exec '[workspace special:control-panel; tile] ghostty -e btop'
        Terminal=false
        Categories=System;Monitor;ConsoleOnly;
        Keywords=system;process;task
      '';

      xdg.dataFile."applications/pavucontrol.desktop".text = ''
        [Desktop Entry]
        Name=PulseAudio Volume Control
        GenericName=Volume Control
        Comment=Adjust the volume level
        Icon=multimedia-volume-control
        Exec=hyprctl dispatch exec '[workspace special:control-panel; float] pavucontrol'
        Terminal=false
        Type=Application
        Categories=AudioVideo;Audio;Mixer;GTK;
        Keywords=pavucontrol;audio;sound;volume;
      '';

      xdg.dataFile."applications/qalculate-gtk.desktop".text = ''
        [Desktop Entry]
        Name=Qalculate!
        GenericName=Calculator
        Comment=Powerful and easy to use calculator
        Icon=qalculate
        Exec=hyprctl dispatch exec '[workspace special:control-panel; float] qalculate-gtk'
        Terminal=false
        Type=Application
        Categories=Utility;Calculator;GTK;
        Keywords=calculator;math;
      '';

      xdg.dataFile."applications/piper.desktop".text = ''
        [Desktop Entry]
        Name=Piper
        GenericName=Gaming Mouse Configuration
        Comment=Configure gaming mice
        Icon=org.freedesktop.Piper
        Exec=hyprctl dispatch exec '[workspace special:control-panel; float] piper'
        Terminal=false
        Type=Application
        Categories=Settings;HardwareSettings;GTK;
        Keywords=gaming;mouse;configuration;
      '';

      xdg.dataFile."applications/org.freedesktop.Piper.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Piper
        Hidden=true
      '';

      xdg.dataFile."applications/org.kde.kwalletmanager5.desktop".text = ''
        [Desktop Entry]
        Name=KWallet Manager
        GenericName=Password Manager
        Comment=Manage KDE Wallet passwords
        Icon=kwalletmanager
        Exec=hyprctl dispatch exec '[workspace special:control-panel; float] kwalletmanager5'
        Terminal=false
        Type=Application
        Categories=Qt;KDE;Settings;Security;
        Keywords=password;wallet;credentials;
      '';

      # Fastfetch configuration
      xdg.configFile."fastfetch/config.jsonc".text = builtins.toJSON {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
        logo = {
          source = "~/dotfiles/modules/desktop/AnomLogo.png";
          type = "kitty-direct";
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
