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
  # stylix.base16Scheme = {
  #   base00 = "171642";
  #   base01 = "354672";
  #   base02 = "965c4c";
  #   base03 = "49aea6";
  #   base04 = "56cbb8";
  #   base05 = "8af1f6";
  #   base06 = "f0f4dd";
  #   base07 = "eef3dd";
  #   base08 = "3da08b";
  #   base09 = "469cbd";
  #   base0A = "429b9f";
  #   base0B = "9a8aaf";
  #   base0C = "c577b3";
  #   base0D = "5996cc";
  #   base0E = "939669";
  #   base0F = "c87e56";
  # };

  # Services.
  services = {
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
    hyprlock.enable = true;
    starship.enable = true;
    steam = {
      enable = true;
      protontricks.enable = true;
      gamescopeSession.enable = true;
      extest.enable = true;
    };
    tmux.enable = true;
    waybar.enable = true;
  };

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [
    pkgs.xdg-desktop-portal-gtk
  ];

  # Nix Flatpak stuff (aka my first flake application)
  services.flatpak.enable = true;
  services.flatpak.remotes = [
    {
      name = "flathub-beta";
      location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
    }
  ];
  services.flatpak.packages = [
    {
      appId = "com.brave.Browser";
      origin = "flathub";
    }
    "io.github.lunarequest.NightPDF"
  ];

  # Allow unfree packages.
  nixpkgs.config.allowUnfree = true;

  # Environment Variables.
  environment.sessionVariables = {
    EDITOR = "zed-editor";
    NIXOS_OZONE_WL = "1";
    TERMINAL = "kitty";
    VISUAL = "zed-editor";
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
    libreoffice-fresh
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
    tdf
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
    youtube-tui
    yt-dlp
    ytfzf
    zed-editor
    zenity
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
