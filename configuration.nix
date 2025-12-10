{
  config,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration-zfs.nix
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
    backupFileExtension = "backup";
    extraSpecialArgs = {inherit inputs;};
    users.${config.mySystem.user.name} = import ./home.nix;
  };

  # age.secrets.restic-password = {
  #   file = ./secrets/restic-password.age;
  #   owner = "root";
  #   mode = "400";
  # };

  # services.restic.backups = {
  #   localbackup = {
  #     initialize = true;
  #     repository = "/backup/restic-repo";
  #     passwordFile = config.age.secrets.restic-password.path;
  #     paths = [
  #       "/home/${config.mySystem.user.name}"
  #       "/etc/nixos"
  #     ];
  #     exclude = [
  #       "/home/${config.mySystem.user.name}/.cache"
  #       "/home/${config.mySystem.user.name}/.local/share/Steam"
  #       "/home/${config.mySystem.user.name}/Downloads"
  #     ];
  #     timerConfig = {
  #       OnCalendar = "daily";
  #       Persistent = true;
  #     };
  #     pruneOpts = [
  #       "--keep-daily 7"
  #       "--keep-weekly 5"
  #       "--keep-monthly 12"
  #     ];
  #   };
  # };

  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://ezkea.cachix.org"
      "https://cache.flakehub.com/"
      "https://nix-community.cachix.org/"
      "https://hyprland.cachix.org/"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
      "cache.flakehub.com:HJhIegLpHXD0u+d+E3s6xL+yN4h7VKQHe+E5xeFj8Kc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  system.stateVersion = "24.11";
}
