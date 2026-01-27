{
  config,
  inputs,
  ...
}: let
  lib = inputs.nixpkgs.lib;
  # Import all .nix files except those whose name or any parent directory starts with _
  import-tree = path:
    let
      allFiles = lib.filesystem.listFilesRecursive path;
      nixFiles = builtins.filter (file:
        lib.hasSuffix ".nix" (toString file)
        && !(lib.hasInfix "/_" (toString file))
        && !(lib.hasPrefix "_" (baseNameOf (toString file)))
      ) allFiles;
    in
      nixFiles;
in {
  imports =
    import-tree ./features
    ++ [
      ./hardware-configuration-zfs.nix
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
    users.${config.mySystem.user.name} = import ./features/core/_home.nix;
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
