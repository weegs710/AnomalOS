# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
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
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024;
    }
  ];
  # Bootloader.
  boot = {
    initrd.services.lvm.enable = true;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  systemd.services.nscd.enable = false;
  # nix.settings.warn-dirty = false;
  networking.hostName = "HX99G"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Nix Settings
  nix.settings = {
    auto-optimise-store = true;
    warn-dirty = false;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # nix.settings.auto-optimise-store = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  xdg.terminal-exec.enable = true;
  xdg.terminal-exec.settings = {default = ["kitty.desktop"];};

  # Env Variables
  environment.sessionVariables.EDITOR = "codium";
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.TERMINAL = "kitty";
  environment.sessionVariables.VISUAL = "codium";
  environment.sessionVariables.XDG_TERMINAL_EDITOR = "kitty";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Hardware Options
  hardware = {
    amdgpu.opencl.enable = true;
    bluetooth.enable = true;
    graphics.enable = true;
    graphics.enable32Bit = true;
    nvidia.modesetting.enable = true;
    steam-hardware.enable = true;
  };

  # Services
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
      defaultSession = "cosmic";
      sddm.enable = true;
    };
    upower.enable = true;
    ollama = {
      acceleration = "rocm";
      enable = true;
    };
    openssh.enable = true;
    xserver.enable = true;
  };

  security.polkit.enable = true;
  security.rtkit.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.weegs = {
    isNormalUser = true;
    description = "weegs";
    extraGroups = ["networkmanager" "wheel"];
    packages = with pkgs; [
    ];
  };

  fonts.packages = (lib.filter lib.isDerivation (lib.attrValues pkgs.nerd-fonts)) ++ [];

  # List programs that you want to enable:
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;
  programs.git.enable = true;
  programs.starship.enable = true;
  programs.tmux.enable = true;
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

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable Steam
  programs.steam.enable = true;
  programs.gamescope.enable = true;
  programs.steam.protontricks.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.steam.extest.enable = true;

  # Enable Fish
  programs.fish.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    pkgs.adwaita-icon-theme
    pkgs.alejandra
    pkgs.anki-bin
    pkgs.brave
    pkgs.btop-rocm
    pkgs.cliphist
    pkgs.dbus
    pkgs.dbus-broker
    pkgs.dunst
    pkgs.fastfetch
    pkgs.gimp3-with-plugins
    pkgs.git
    pkgs.grim
    pkgs.jq
    pkgs.kdePackages.kwallet-pam
    pkgs.kitty
    pkgs.libnotify
    pkgs.libportal
    pkgs.libreoffice-fresh
    pkgs.lm_sensors
    pkgs.lutris
    pkgs.mpv
    pkgs.nixd
    pkgs.nixfmt-rfc-style
    pkgs.obs-studio
    pkgs.pamixer
    pkgs.pavucontrol
    pkgs.piper
    pkgs.protonup-qt
    pkgs.qview
    pkgs.slurp
    pkgs.tdf
    pkgs.tldr
    pkgs.transmission_4-gtk
    pkgs.vscodium
    pkgs.wget
    pkgs.wireplumber
    pkgs.wl-clipboard
    pkgs.wl-clip-persist
    pkgs.wlogout
    pkgs.wlsunset
    pkgs.xdg-dbus-proxy
    pkgs.yazi
    pkgs.zenity
  ];

  # Set Fish as global default shell
  users.defaultUserShell = pkgs.fish;

  environment.shellAliases = {
    nrs = "sudo nixos-rebuild switch";
    claude = "ollama run GandalfBaum/llama3.1-claude3.7";
    cgem = "ollama run codegemma";
    stfu = "pkill ollama";
    tdeath = "pkill tmux";
    pkcp = "pkill cosmic-panel";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
