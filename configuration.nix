{ config, inputs, ... }:

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

  mySystem = {
    hostName = "HX99G";
    user = {
      name = "weegs";
      description = "weegs";
      extraGroups = [
        "cdrom"
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
      aiAssistant = true;
    };

    hardware = {
      amd = true;
      bluetooth = true;
      steam = true;
    };
  };

  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users.${config.mySystem.user.name} = import ./home.nix;
  };

  age.secrets.restic-password = {
    file = ./secrets/restic-password.age;
    owner = "root";
    mode = "400";
  };

  services.restic.backups = {
    localbackup = {
      initialize = true;
      repository = "/backup/restic-repo";
      passwordFile = config.age.secrets.restic-password.path;
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

  system.stateVersion = "24.11";
}
