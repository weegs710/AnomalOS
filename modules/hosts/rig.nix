{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.Rig = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs;};
    modules =
      # Automatically import all nixosModules defined by flake-parts
      (builtins.attrValues self.nixosModules)
      ++ [
        # Hardware configuration
        ../../hardware-configuration-zfs.nix

        # Home Manager
        inputs.home-manager.nixosModules.default

        # Host-specific configuration
        ({config, ...}: {
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
            users.${config.mySystem.user.name} = {
              home.username = config.mySystem.user.name;
              home.homeDirectory = "/home/${config.mySystem.user.name}";
              home.stateVersion = "25.05";
              programs.home-manager.enable = true;
            };
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
        })
      ];
  };
}
