{
  lib,
  config,
  pkgs,
  ...
}: {
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

  # Networking Options.
  networking = {
    hostName = "HX99G";
    networkmanager.enable = true;
    firewall = {
      enable = false;
      allowedTCPPorts = [];
      allowedUDPPorts = [];
    };
  };

  # Timezone Options.
  time.timeZone = "America/New_York";

  # Configure keymap in X11.
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Stylix Options.
  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/purpledream.yaml";
  stylix.image = ./home/.config/hypr/monster.jpg;

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
      cosmic.enable = true;
      cosmic.xwayland.enable = true;
    };
    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "weegs";
      defaultSession = "hyprland";
      sddm.enable = true;
    };
    upower.enable = true;
    ollama = {
      acceleration = "rocm";
      enable = true;
    };
    openssh.enable = true;
    xserver.enable = true;
    hypridle.enable = true;
  };

  systemd.services.nscd.enable = false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.weegs = {
    isNormalUser = true;
    description = "weegs";
    extraGroups = ["networkmanager" "wheel"];
    packages = with pkgs; [
    ];
  };

  # Set Fish as global default shell.
  users.defaultUserShell = pkgs.fish;

  # Declare ALL Nerd Fonts.
  fonts.packages = (lib.filter lib.isDerivation (lib.attrValues pkgs.nerd-fonts)) ++ [];

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
    "com.discordapp.Discord"
    "com.github.tchx84.Flatseal"
    "io.github.lunarequest.NightPDF"
    "dev.edfloreshz.CosmicTweaks"
  ];

  # Allow unfree packages.
  nixpkgs.config.allowUnfree = true;

  # Environment Variables.
  environment.sessionVariables = {
    EDITOR = "codium";
    NIXOS_OZONE_WL = "1";
    TERMINAL = "kitty";
    VISUAL = "codium";
    XDG_TERMINAL_EDITOR = "kitty";
  };

  # Aliases.
  environment.shellAliases = {
    nrs = "sudo nixos-rebuild switch";
    claude = "ollama run GandalfBaum/llama3.1-claude3.7";
    cgem = "ollama run codegemma";
    stfu = "pkill ollama";
    tdeath = "pkill tmux";
    pkcp = "pkill cosmic-panel";
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
    dbus
    dbus-broker
    dunst
    fastfetch
    gimp3-with-plugins
    git
    grim
    jq
    kdePackages.kwallet-pam
    kitty
    libnotify
    libportal
    libreoffice-fresh
    lm_sensors
    lutris
    mpv
    nixd
    nixfmt-rfc-style
    obs-studio
    pamixer
    pavucontrol
    piper
    protonup-qt
    qview
    rofi
    slurp
    swww
    tdf
    tldr
    transmission_4-gtk
    vscodium
    wget
    wireplumber
    wl-clipboard
    wl-clip-persist
    wlogout
    wlsunset
    xdg-dbus-proxy
    yazi
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
