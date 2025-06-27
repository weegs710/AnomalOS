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
  boot.loader.grub.enable = false;
  boot.loader.grub.efiSupport = false;
  boot.initrd.services.lvm.enable = true;
  boot.loader.systemd-boot.enable = true;
  systemd.services.nscd.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  nix.settings.warn-dirty = false;
  networking.hostName = "HX99G"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.auto-optimise-store = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  xdg.terminal-exec.enable = true;
  xdg.terminal-exec.settings = {default = ["kitty.desktop"];};

  # Env Variables
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.TERMINAL = "kitty";
  environment.sessionVariables.XDG_TERMINAL_EDITOR = "kitty";
  environment.sessionVariables.EDITOR = "codium";
  environment.sessionVariables.VISUAL = "codium";

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  services.desktopManager.cosmic.xwayland.enable = true;
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = false;

  # Enable Bluetooth
  hardware.bluetooth.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  hardware.graphics.enable32Bit = true;
  hardware = {
    graphics.enable = true;
    nvidia.modesetting.enable = true;
  };
  hardware.amdgpu.opencl.enable = true;
  security.polkit.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.weegs = {
    isNormalUser = true;
    description = "weegs";
    extraGroups = ["networkmanager" "wheel"];
    packages = with pkgs; [
    ];
  };

  fonts.packages = (lib.filter lib.isDerivation (lib.attrValues pkgs.nerd-fonts)) ++ [];
  services.ratbagd.enable = true;

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "weegs";
  services.displayManager.defaultSession = "cosmic";
  # List programs that you want to enable:
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;
  programs.gamescope.enable = true;
  programs.git.enable = true;
  programs.starship.enable = true;
  programs.tmux.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [
    pkgs.xdg-desktop-portal-gtk
  ];

  # List services that you want to enable:
  services.atuin.enable = true;
  services.upower.enable = true;

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
    "com.valvesoftware.Steam"
  ];
  services.ollama.acceleration = "rocm";
  services.ollama.enable = true;

  services.openssh.enable = true;
  services.pipewire.wireplumber.enable = config.services.pipewire.enable;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

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

  environment.shellAliases = {
    nrs = "sudo nixos-rebuild switch";
    claude = "ollama run GandalfBaum/llama3.1-claude3.7";
    cgem = "ollama run codegemma";
    stfu = "pkill ollama";
    tdeath = "pkill tmux";
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
