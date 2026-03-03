{
  inputs,
  self,
  ...
}: let
  rig = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs;};
    modules =
      # Automatically import all nixosModules defined by flake-parts
      (builtins.attrValues self.nixosModules)
      ++ [
        # Hardware configuration
        ./_hardware-configuration.nix

        # Host-specific configuration
        ({...}: {
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

          nix.settings = {
            substituters = [
              "https://cache.nixos.org/"
              "https://ezkea.cachix.org"
              "https://nix-community.cachix.org/"
              "https://hyprland.cachix.org/"
              "https://attic.xuyh0120.win/lantian"
            ];
            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
              "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
            ];
          };

          system.stateVersion = "24.11";
        })
      ];
  };
in {
  flake.nixosConfigurations.Rig = rig;
  flake.rig = rig;
}
