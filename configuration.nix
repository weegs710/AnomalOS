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
    trusted-users = [
      "weegs"
    ];
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
  stylix.targets.gtk.enable = true;
  stylix.targets.qt.enable = true;

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

  systemd.services.nscd.enable = false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.fish;
    users.weegs = {
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
  };

  # Declare ALL Nerd Fonts.
  fonts.packages = (lib.filter lib.isDerivation (lib.attrValues pkgs.nerd-fonts)) ++ [ ];

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
  };

  # Aliases.
  environment.shellAliases = {
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
    inputs.drugtracker2.packages.${pkgs.system}.drug
    adwaita-icon-theme
    alarm-clock-applet
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
    hyprshot
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
    nh
    ns # Thanks @Jet for helping me get this going properly ^^
    obs-studio
    pamixer
    pavucontrol
    piper
    protonup-qt
    qalculate-gtk
    qview
    rofi
    slurp
    superfile
    swww
    tldr
    ueberzugpp
    transmission_4-gtk
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
