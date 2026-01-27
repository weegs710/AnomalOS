{
  config,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration-zfs.nix

    # Core features (always enabled)
    ./features/core/options.nix
    ./features/core/boot.nix
    ./features/core/networking.nix
    ./features/core/nix-daemon.nix
    ./features/core/users.nix
    ./features/core/zfs.nix
    ./features/core/xdg.nix
    ./features/core/packages.nix
    ./features/core/fish.nix
    ./features/core/oh-my-posh.nix
    ./features/core/ghostty.nix
    ./features/core/superfile.nix
    ./features/core/desktop-services.nix
    ./features/core/desktop-packages.nix

    # Desktop
    ./features/hyprland
    ./features/noctalia
    ./features/desktop/kdeconnect.nix
    ./features/desktop/flatpak.nix
    ./features/desktop/autotrash.nix
    ./features/desktop/btop.nix
    ./features/desktop/qalc.nix
    ./features/desktop/timg.nix
    ./features/desktop/pulsemixer.nix
    ./features/desktop/udiskie.nix
    ./features/desktop/fastfetch.nix
    ./features/desktop/helium.nix
    ./features/desktop/vesktop.nix
    ./features/desktop/xdg-apps.nix
    ./features/desktop/termfilechooser.nix

    # Editors
    ./features/editors/zed.nix
    ./features/editors/tmux.nix

    # Media
    ./features/media/audio.nix
    ./features/media/creation.nix
    ./features/media/scraping.nix
    ./features/media/mpd.nix

    # Gaming
    ./features/gaming/steam.nix
    ./features/gaming/mangohud.nix
    ./features/gaming/decky.nix
    ./features/gaming/packages.nix

    # Security
    ./features/security/dnscrypt.nix
    ./features/security/firewall.nix
    ./features/security/suricata.nix
    ./features/security/yubikey.nix
    ./features/security/services.nix

    # Development
    ./features/development/languages.nix
    ./features/development/vm.nix
    ./features/development/android-webcam.nix
    ./features/development/claude-code.nix
    ./features/development/tools.nix

    # Home Manager integration
    inputs.home-manager.nixosModules.default
  ];

  mySystem = {
    hostName = "HX99G";
    user = {
      name = "weegs";
      description = "weegs";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };

    features = {
      desktop = true;
      security = true;
      yubikey = true;
      claudeCode = true;
      development = true;
      gaming = true;
      flatpak = true;
      media = true;
      kdeconnect = true;
      vm = true;
      androidWebcam = true;
    };

    hardware = {
      amd = true;
      bluetooth = true;
      steam = true;
    };

    security = {
      dnscrypt = true;
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {inherit inputs;};
    users.${config.mySystem.user.name} = import ./features/core/home.nix;
  };

  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://ezkea.cachix.org"
      "https://nix-community.cachix.org/"
      "https://hyprland.cachix.org/"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  system.stateVersion = "24.11";
}
