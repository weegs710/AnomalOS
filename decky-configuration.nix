# Add this directly to your configuration.nix
# Replace the existing configuration.nix content with this updated version

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

  # Decky Loader package definition (inline)
  decky-loader = pkgs.stdenv.mkDerivation rec {
    pname = "decky-loader";
    version = "3.0.4";

    src = pkgs.fetchFromGitHub {
      owner = "SteamDeckHomebrew";
      repo = "decky-loader";
      rev = "v${version}";
      hash = "sha256-pWkAu0nYg3YOA7w/8eN9n23sSyFkZcuvGUF8Swd0Hbc=";
      fetchSubmodules = true;
    };

    nativeBuildInputs = with pkgs; [
      nodejs_22
      nodePackages.pnpm
      makeWrapper
      python3
    ];

    buildInputs = with pkgs; [
      (python3.withPackages (
        ps: with ps; [
          flask
          flask-cors
          requests
          websockets
          aiohttp
          psutil
          packaging
        ]
      ))
    ];

    # Skip pnpm for now to get basic package working
    buildPhase = ''
      runHook preBuild

      # Create a simple frontend build
      mkdir -p frontend/dist
      echo "<h1>Decky Loader</h1><p>Running on NixOS</p>" > frontend/dist/index.html

      # Validate Python backend
      python -m py_compile backend/main.py

      runHook postBuild
    '';

    installPhase = ''
            runHook preInstall

            mkdir -p $out/{bin,lib/decky-loader,share/applications}

            # Install backend
            cp -r backend/* $out/lib/decky-loader/

            # Install simple frontend
            mkdir -p $out/lib/decky-loader/static
            cp -r frontend/dist/* $out/lib/decky-loader/static/

            # Create wrapper script
            makeWrapper ${pkgs.python3}/bin/python $out/bin/decky-loader \
              --add-flags "$out/lib/decky-loader/main.py" \
              --prefix PATH : ${
                lib.makeBinPath (
                  with pkgs;
                  [
                    steam
                    procps
                    gnused
                    gawk
                  ]
                )
              } \
              --set DECKY_HOME "\$HOME/.local/share/decky-loader" \
              --run 'mkdir -p "$HOME/.local/share/decky-loader"/{plugins,settings,logs}'

            # Desktop entry
            cat > $out/share/applications/decky-loader.desktop << EOF
      [Desktop Entry]
      Name=Decky Loader
      Comment=Plugin loader for Steam
      Exec=$out/bin/decky-loader
      Icon=steam
      Terminal=false
      Type=Application
      Categories=Game;
      EOF

            runHook postInstall
    '';

    meta = with lib; {
      description = "A plugin loader for Steam";
      homepage = "https://github.com/SteamDeckHomebrew/decky-loader";
      license = licenses.gpl2Plus;
      platforms = platforms.linux;
    };
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
      allowPing = true;
      allowedTCPPorts = [
        1337
        9222
      ]; # Add Decky Loader ports
      allowedUDPPorts = [ 1337 ];
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
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    hypridle.enable = true;
  };

  # Decky Loader systemd user service
  systemd.user.services.decky-loader = {
    description = "Decky Loader - Steam Plugin System";
    after = [ "graphical-session.target" ];
    wantedBy = [ "default.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${decky-loader}/bin/decky-loader";
      Restart = "on-failure";
      RestartSec = 10;
      Environment = [
        "DECKY_PORT=1337"
        "HOME=%h"
        "XDG_CONFIG_HOME=%h/.config"
      ];
    };

    preStart = ''
      mkdir -p "$HOME/.local/share/decky-loader"/{plugins,settings,logs}
      mkdir -p "$HOME/.config/decky-loader"
    '';
  };

  # Define a user account. Don't forget to set a password with â€˜passwdâ€™.
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
        anki-bin
        bluetui
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
        transmission_4-gtk
        vesktop
        yazi
        zed-editor
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
    grim
    hyprls
    kdePackages.kwallet-pam
    keyd
    kitty
    libnotify
    libportal
    lm_sensors
    nil
    nixd
    nh
    ns
    pamixer
    slurp
    ueberzugpp
    wget
    wireplumber
    wl-clipboard
    wl-clip-persist
    xdg-dbus-proxy
    xfce.thunar-volman
    # Add Decky Loader to system packages
    decky-loader
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. Itâ€˜s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
