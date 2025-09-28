{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/options.nix
    ./modules/core
    ./modules/security
    ./modules/desktop
    ./modules/development
    ./modules/gaming
    inputs.home-manager.nixosModules.default
  ];

  # System configuration
  mySystem = {
    hostName = "HX99G";
    user = {
      name = "weegs";
      description = "weegs";
      extraGroups = [ "networkmanager" "wheel" ];
    };

    # Feature toggles - customize as needed
    features = {
      desktop = true;
      security = true;
      yubikey = true;           # Set to false to disable YubiKey features
      claudeCode = true;        # Set to false to disable Claude Code
      development = true;
      gaming = true;
    };

    # Hardware features
    hardware = {
      amd = true;
      bluetooth = true;
      steam = true;
    };
  };

  # Home Manager configuration
  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users.${config.mySystem.user.name} = import ./home.nix;
  };

  # Backup service (optional but recommended)
  services.restic.backups = {
    localbackup = {
      initialize = true;
      repository = "/backup/restic-repo";
      passwordFile = "/etc/nixos/restic-password";
      paths = [
        "/home/${config.mySystem.user.name}"
        "/etc/nixos"
      ];
      exclude = [
        "/home/${config.mySystem.user.name}/.cache"
        "/home/${config.mySystem.user.name}/.local/share/Steam"
        "/home/${config.mySystem.user.name}/Downloads"
      ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
      ];
    };
  };

  # System state version
  system.stateVersion = "24.11";
}