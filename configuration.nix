{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
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

  # Swap Size Options.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024;
    }
  ];

  # Bootloader Options.
  boot = {
    initrd.services.lvm.enable = true;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # Security Options.
  security.polkit.enable = true;
  security.rtkit.enable = true;

  # Nix Settings.
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };
  nix.settings = {
    auto-optimise-store = true;
    warn-dirty = false;
    experimental-features = [
      "nix-command"
      "flakes"
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
    networkmanager.enable = true;
    firewall = {
      enable = false;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  # Timezone Options.
  time.timeZone = "America/New_York";

  # Stylix Options.
  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/shades-of-purple.yaml";
  stylix.image = ./monster.jpg;
  stylix.polarity = "dark";

  # Services.
  services = {
    devmon.enable = true;
    flatpak = {
      enable = true;
      packages = [
        {
          appId = "com.brave.Browser";
          origin = "flathub";
        }
        "io.github.lunarequest.NightPDF"
      ];
      remotes = [
        {
          name = "flathub-beta";
          location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
        }
      ];
    };
    pulseaudio.enable = false;
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
      cosmic.enable = false;
      cosmic.xwayland.enable = false;
      gnome.enable = false;
    };
    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "weegs";
      defaultSession = "hyprland";
      sddm.enable = true;
      gdm.enable = false;
    };
    upower.enable = true;
    ollama = {
      acceleration = "rocm";
      enable = true;
    };
    openssh.enable = true;
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    hypridle.enable = true;
  };

  # Daemonized Auto-Upgrade
  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = [
      "--update-input"
      "nixpkgs"
      "-L"
    ];
    dates = "02:00";
    randomizedDelaySec = "30min";
  };
  systemd.services.nscd.enable = false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.weegs = {
    isNormalUser = true;
    description = "weegs";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      hello
    ];
  };

  # Set Fish as global default shell.
  users.defaultUserShell = pkgs.fish;

  # Declare ALL Nerd Fonts.
  fonts.packages = (lib.filter lib.isDerivation (lib.attrValues pkgs.nerd-fonts)) ++ [ ];

  # Program Options:
  programs = {
    appimage = {
      enable = true;
      binfmt = true;
    };
    fish.enable = true;
    gamescope.enable = true;
    git.enable = true;
    hyprland.enable = true;
    hyprland.package = inputs.hyprland.packages."${pkgs.system}".hyprland;
    hyprlock.enable = true;
    starship.enable = true;
    steam = {
      enable = true;
      protontricks.enable = true;
      gamescopeSession.enable = true;
      extest.enable = true;
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
    EDITOR = "zeditor";
    NIXOS_OZONE_WL = "1";
    TERMINAL = "kitty";
    VISUAL = "zeditor";
    XDG_TERMINAL_EDITOR = "kitty";
  };

  # Aliases.
  environment.shellAliases = {
    nrs = "sudo nixos-rebuild switch";
    cgem = "ollama run codegemma";
    stfu = "pkill ollama";
    tdeath = "pkill tmux";
    ns = "nix run github:michael-c-buckley/nixos#ns";
  };

  # System Packages.
  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
    alejandra
    anki-bin
    bluetui
    brave
    btop-rocm
    cliphist
    curl
    dbus
    dbus-broker
    dunst
    fastfetch
    fzf
    gimp3-with-plugins
    git
    grim
    hyprls
    jq
    kdePackages.kwallet-pam
    keyd
    kitty
    libnotify
    libportal
    lm_sensors
    lutris
    mpv
    nil
    nixd
    obs-studio
    pamixer
    pavucontrol
    piper
    protonup-qt
    qview
    rofi
    slurp
    superfile
    swww
    tldr
    ueberzugpp
    transmission_4-gtk
    tutanota-desktop
    vesktop
    wget
    wireplumber
    wl-clipboard
    wl-clip-persist
    wlogout
    wlsunset
    xdg-dbus-proxy
    xfce.thunar-volman
    zed-editor
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
