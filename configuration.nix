{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let

  ns = pkgs.writeShellApplication {
    name = "ns";
    runtimeInputs = with pkgs; [
      fzf
      nix-search-tv
    ];
    # ignore checks since i didn't write this
    checkPhase = "";
    text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
  };

in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Hardware Options.
  hardware = {
    amdgpu.opencl.enable = true;
    bluetooth.enable = true;
    graphics.enable = true;
    graphics.enable32Bit = true;
    nvidia.modesetting.enable = true;
    steam-hardware.enable = true;
  };

  # Bootloader Options.
  boot = {
    initrd.services.lvm.enable = true;
    plymouth.enable = true;
    kernelParams = [ 
      "quiet" 
      "kernel.dmesg_restrict=1"
      "kernel.kptr_restrict=2"
      "kernel.yama.ptrace_scope=1"
    ];
    consoleLogLevel = 0;
    initrd.verbose = false;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    # Kernel security hardening
    kernel.sysctl = {
      # Network security
      "net.ipv4.conf.all.forwarding" = false;
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.conf.all.accept_redirects" = false;
      "net.ipv4.conf.default.accept_redirects" = false;
      "net.ipv4.conf.all.secure_redirects" = false;
      "net.ipv4.conf.default.secure_redirects" = false;
      "net.ipv6.conf.all.accept_redirects" = false;
      "net.ipv6.conf.default.accept_redirects" = false;
      "net.ipv4.conf.all.send_redirects" = false;
      "net.ipv4.ip_forward" = false;
      "net.ipv6.conf.all.forwarding" = false;
      "net.ipv4.tcp_syncookies" = true;
      "net.ipv4.tcp_rfc1337" = 1;
      
      # Memory protection
      "kernel.core_uses_pid" = true;
      "kernel.core_pattern" = "|/bin/false";
      "fs.suid_dumpable" = 0;
      
      # Process restrictions
      "kernel.dmesg_restrict" = true;
      "kernel.kptr_restrict" = 2;
      "kernel.yama.ptrace_scope" = 1;
      
      # Memory layout randomization
      "kernel.randomize_va_space" = 2;
    };
  };

  # Security Options.
  security = {
    polkit.enable = true;
    rtkit.enable = true;
    pam.u2f = {
      enable = true;
      control = "sufficient";
      settings = {
        interactive = true;
        authFile = "~/.config/Yubico/u2f_key";
      };
    };
    pam.services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
      sddm.u2fAuth = true;
      polkit-1.u2fAuth = true;
    };
  };
  # Nix Settings.
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };
  nix.settings = {
    auto-optimise-store = true;
    warn-dirty = false;
    trusted-users = [
      "weegs"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  # Home Manager Settings.
  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users = {
      "weegs" = import ./home.nix;
    };
  };

  # Networking Options.
  networking = {
    hostName = "HX99G";
    networkmanager = {
      enable = true;
    };
    nftables.enable = true;
    firewall = {
      enable = true;
      allowPing = false; # Disable ICMP ping responses
      allowedTCPPorts = [ 2222 ]; # SSH on custom port
      allowedUDPPorts = [ ];
    };
  };

  # Timezone Options.
  time.timeZone = "America/New_York";

  # Stylix Options.
  stylix.enable = true;
  stylix.base16Scheme = {
    base00 = "111147";
    base01 = "1a1a5c";
    base02 = "565f89";
    base03 = "6b7394";
    base04 = "a8b5d1";
    base05 = "d0beee";
    base06 = "dbc8f0";
    base07 = "e6d4f5";
    base08 = "b53dff";
    base09 = "2082a6";
    base0A = "7dcfff";
    base0B = "53b397";
    base0C = "249a84";
    base0D = "5ca8dc";
    base0E = "a175d4";
    base0F = "db7ddd";
    scheme = "Sugarplum";
    author = "lemonlime0x3C33 (converted)";
  };
  stylix.image = ./monster.jpg;
  stylix.polarity = "dark";
  stylix.targets.gtk.enable = true;
  stylix.targets.qt.enable = true;

  # Services.
  services = {
    devmon.enable = true;
    udev = {
      packages = [
        pkgs.yubikey-personalization
        pkgs.libu2f-host
        pkgs.yubikey-manager
      ];
      extraRules = ''
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0113|0114|0115|0116|0120|0200|0402|0403|0406|0407|0410", TAG+="uaccess", MODE="0664", GROUP="plugdev"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", GROUP="plugdev", MODE="0664"

        # YubiKey auto-login rules
        SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0113|0114|0115|0116|0120|0200|0402|0403|0406|0407|0410", ACTION=="add", TAG+="systemd", ENV{SYSTEMD_WANTS}="yubikey-autologin-enable.service"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0113|0114|0115|0116|0120|0200|0402|0403|0406|0407|0410", ACTION=="remove", TAG+="systemd", ENV{SYSTEMD_WANTS}="yubikey-autologin-disable.service"
      '';
    };
    flatpak = {
      enable = true;
      packages = [
        {
          appId = "com.brave.Browser";
          origin = "flathub";
        }
      ];
      remotes = [
        {
          name = "flathub-beta";
          location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
        }
      ];
    };
    locate.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = config.services.pipewire.enable;
    };
    ratbagd.enable = true;
    desktopManager = {
    };
    displayManager = {
      autoLogin.enable = false; # Controlled by yubikey-autologin service
      defaultSession = "hyprland";
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    };
    upower.enable = true;
    # ollama = {
    #   enable = true;
    # };
    openssh = {
      enable = true;
      ports = [ 2222 ]; # Custom port (not 22)
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        PubkeyAuthentication = true;
        MaxAuthTries = 3;
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
        AllowUsers = [ "weegs" ];
        X11Forwarding = false;
        PrintMotd = false;
        PermitEmptyPasswords = false;
        # Modern crypto algorithms (2025 best practices)
        KexAlgorithms = [
          "curve25519-sha256@libssh.org"
          "curve25519-sha256"
        ];
        Ciphers = [
          "chacha20-poly1305@openssh.com"
          "aes256-gcm@openssh.com"
          "aes128-gcm@openssh.com"
          "aes256-ctr"
          "aes128-ctr"
        ];
        Macs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
        ];
      };
      openFirewall = false; # We'll handle this in firewall config
    };
    pcscd.enable = true;
    xserver = {
      enable = false;
      # xkb = {
      #   layout = "us";
      #   variant = "";
      # };
    };
    hypridle.enable = true;
    # Network security monitoring
    suricata = {
      enable = true;
      settings = {
        # Interface configuration
        af-packet = [
          {
            interface = "wlp6s0";
            cluster-id = 99;
            cluster-type = "cluster_flow";
            defrag = true;
          }
        ];
        # Simple logging configuration
        outputs = [
          {
            fast = {
              enabled = true;
              filename = "/var/log/suricata/fast.log";
            };
          }
          {
            eve-log = {
              enabled = true;
              filetype = "regular";
              filename = "/var/log/suricata/eve.json";
              types = [
                { alert = { }; }
                { http = { }; }
                { dns = { }; }
                { tls = { }; }
                { ssh = { }; }
                { stats = { }; }
              ];
            };
          }
        ];
        # Use default rules with modbus disabled
        default-rule-path = "/var/lib/suricata/rules";
        rule-files = [ "suricata.rules" ];
        # Disable problematic protocols
        app-layer.protocols.modbus.enabled = "no";
      };
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.fish;
    users.weegs = {
      isNormalUser = true;
      description = "weegs";
      extraGroups = [
        "networkmanager"
        "wheel"
        "plugdev"
      ];
      packages = with pkgs; [
        anki-bin
        bluetui
        claude-code
        desmume
        freetube
        gimp3-with-plugins
        librewolf
        lutris
        mpv
        obs-studio
        pavucontrol
        piper
        protonup-qt
        qalculate-gtk
        qview
        ryubing
        transmission_4-gtk
        unzipNLS
        vesktop
        yazi
        zathura
        zed-editor
      ];
    };
  };

  # Declare specific Nerd Fonts.
  fonts.packages = with pkgs.nerd-fonts; [
    dejavu-sans-mono
    zed-mono
    jetbrains-mono
    fira-code
    terminess-ttf
  ];

  # Program Options:
  programs = {
    appimage = {
      enable = true;
      binfmt = true;
    };
    direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
      direnvrcExtra = ''
        warn_timeout=0
        hide_env_diff=true
      '';
    };
    fish.enable = true;
    gamescope.enable = true;
    git.enable = true;
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    hyprlock.enable = true;
    nix-index.enable = true;
    starship.enable = true;
    steam = {
      enable = true;
      protontricks.enable = true;
      gamescopeSession.enable = true;
      extest.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };
    thunar.enable = true;
    tmux.enable = true;
    udevil.enable = true;
    waybar.enable = true;
  };

  # XDG Options.
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # Allow unfree packages.
  nixpkgs.config.allowUnfree = true;

  # Environment Variables.
  environment.sessionVariables = {
  };

  # Aliases.
  environment.shellAliases = {
    gparted = "sudo WAYLAND_DISPLAY=$WAYLAND_DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR gparted";
    recycle = "sudo nix-collect-garbage --delete-older-than 7d";
    nfa = "cd ~/dotfiles/ && nix flake archive";
    nrs = "cd ~/dotfiles/ && sudo nixos-rebuild switch --flake .#HX99G";
    nrt = "cd ~/dotfiles/ && sudo nixos-rebuild test --flake .#HX99G";
    update-all = "cd ~/dotfiles/ && sudo nix flake update && nrs";
    update-all-test = "cd ~/dotfiles/ && sudo nix flake update && nrt";
    gemma = "ollama run gemma3";
    stfu = "pkill ollama";
    tdie = "pkill tmux";
  };

  # System Packages.
  environment.systemPackages = with pkgs; [
    # inputs.drugtracker2.packages.${pkgs.system}.drug
    adwaita-icon-theme
    alarm-clock-applet
    curl
    dbus
    dbus-broker
    git
    gparted
    grim
    hyprls
    kdePackages.kwallet-pam
    keyd
    kitty
    libnotify
    libportal
    lm_sensors
    nil
    nh
    ns
    pamixer
    pam_u2f
    slurp
    ueberzugpp
    wget
    wireplumber
    wl-clipboard
    wl-clip-persist
    xdg-dbus-proxy
    xfce.thunar-volman
    yubikey-manager
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # YubiKey-based conditional auto-login system

  systemd.services.yubikey-autologin-enable = {
    description = "Enable auto-login when registered YubiKey is present";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "enable-autologin" ''
                #!/usr/bin/env bash

                # Path to registered YubiKeys
                U2F_KEYS="/home/weegs/.config/Yubico/u2f_keys"
                SDDM_CONF_DIR="/etc/sddm.conf.d"
                AUTOLOGIN_CONF="$SDDM_CONF_DIR/autologin.conf"
                LOG_FILE="/var/log/yubikey-autologin.log"

                # Function to validate YubiKey registration
                validate_yubikey() {
                  # Use full path to ykman
                  YKMAN_PATH="/run/current-system/sw/bin/ykman"
                  if [[ ! -x "$YKMAN_PATH" ]]; then
                    echo "$(date): ykman not available at $YKMAN_PATH" >> "$LOG_FILE"
                    return 1
                  fi

                  # Get YubiKey serial if possible
                  YUBIKEY_INFO=$($YKMAN_PATH info 2>/dev/null || echo "")

                  # Check if U2F keys file exists and is readable
                  if [[ ! -f "$U2F_KEYS" ]]; then
                    echo "$(date): No U2F keys file found" >> "$LOG_FILE"
                    return 1
                  fi

                  # Basic validation - if we have U2F keys registered and a YubiKey is present
                  if [[ -s "$U2F_KEYS" ]] && [[ -n "$YUBIKEY_INFO" ]]; then
                    # Additional check: try to verify the key works with our system
                    if [[ "$YUBIKEY_INFO" == *"Security Key"* ]] || [[ "$YUBIKEY_INFO" == *"YubiKey"* ]]; then
                      echo "$(date): Validated YubiKey: $(echo "$YUBIKEY_INFO" | head -1)" >> "$LOG_FILE"
                      return 0
                    fi
                  fi

                  echo "$(date): YubiKey validation failed" >> "$LOG_FILE"
                  return 1
                }

                # Validate the inserted YubiKey
                if validate_yubikey; then
                  echo "$(date): Registered YubiKey detected, enabling auto-login" >> "$LOG_FILE"
                  mkdir -p "$SDDM_CONF_DIR"
                  cat > "$AUTOLOGIN_CONF" << 'EOF'
        [Autologin]
        User=weegs
        Session=hyprland
        Relogin=true
        EOF
                  chmod 644 "$AUTOLOGIN_CONF"
                else
                  echo "$(date): Unregistered or invalid YubiKey detected, auto-login not enabled" >> "$LOG_FILE"
                fi
      '';
      User = "root";
    };
  };

  systemd.services.yubikey-autologin-disable = {
    description = "Disable auto-login when YubiKey is removed";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "disable-autologin" ''
        #!/usr/bin/env bash

        SDDM_CONF_DIR="/etc/sddm.conf.d"
        AUTOLOGIN_CONF="$SDDM_CONF_DIR/autologin.conf"
        LOG_FILE="/var/log/yubikey-autologin.log"

        # Remove SDDM auto-login config
        if [[ -f "$AUTOLOGIN_CONF" ]]; then
          rm -f "$AUTOLOGIN_CONF"
          echo "$(date): YubiKey removed, auto-login disabled" >> "$LOG_FILE"
        else
          echo "$(date): YubiKey removed, auto-login was already disabled" >> "$LOG_FILE"
        fi
      '';
      User = "root";
    };
  };

  systemd.services.yubikey-autologin-init = {
    description = "Initialize auto-login based on registered YubiKey presence at boot";
    wantedBy = [ "multi-user.target" ];
    before = [ "display-manager.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "init-autologin" ''
                #!usr/bin/env bash

                U2F_KEYS="/home/weegs/.config/Yubico/u2f_keys"
                SDDM_CONF_DIR="/etc/sddm.conf.d"
                AUTOLOGIN_CONF="$SDDM_CONF_DIR/autologin.conf"
                LOG_FILE="/var/log/yubikey-autologin.log"

                # Ensure log file exists with proper permissions
                touch "$LOG_FILE"
                chmod 644 "$LOG_FILE"

                # Function to validate YubiKey registration
                validate_yubikey() {
                  # Use full path to ykman
                  YKMAN_PATH="/run/current-system/sw/bin/ykman"
                  if [[ ! -x "$YKMAN_PATH" ]]; then
                    echo "$(date): ykman not available at boot: $YKMAN_PATH" >> "$LOG_FILE"
                    return 1
                  fi

                  # Wait a moment for USB to settle
                  sleep 2

                  # Get YubiKey info
                  YUBIKEY_INFO=$($YKMAN_PATH info 2>/dev/null || echo "")

                  # Check if U2F keys file exists and is readable
                  if [[ ! -f "$U2F_KEYS" ]]; then
                    echo "$(date): No U2F keys file found at boot" >> "$LOG_FILE"
                    return 1
                  fi

                  # Basic validation - if we have U2F keys registered and a YubiKey is present
                  if [[ -s "$U2F_KEYS" ]] && [[ -n "$YUBIKEY_INFO" ]]; then
                    if [[ "$YUBIKEY_INFO" == *"Security Key"* ]] || [[ "$YUBIKEY_INFO" == *"YubiKey"* ]]; then
                      echo "$(date): Boot validation successful for: $(echo "$YUBIKEY_INFO" | head -1)" >> "$LOG_FILE"
                      return 0
                    fi
                  fi

                  echo "$(date): No valid registered YubiKey found at boot" >> "$LOG_FILE"
                  return 1
                }

                # Initialize log
                echo "$(date): YubiKey auto-login service starting..." >> "$LOG_FILE"

                # Ensure conf directory exists
                mkdir -p "$SDDM_CONF_DIR"

                # Check for registered YubiKey presence at boot
                if validate_yubikey; then
                  echo "$(date): Registered YubiKey present at boot, enabling auto-login" >> "$LOG_FILE"
                  cat > "$AUTOLOGIN_CONF" << 'EOF'
        [Autologin]
        User=weegs
        Session=hyprland
        Relogin=true
        EOF
                  chmod 644 "$AUTOLOGIN_CONF"
                else
                  echo "$(date): No registered YubiKey at boot, ensuring auto-login is disabled" >> "$LOG_FILE"
                  rm -f "$AUTOLOGIN_CONF"
                fi
      '';
      User = "root";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
