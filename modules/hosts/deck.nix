{
  inputs,
  self,
  ...
}: let
  deck = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs;};
    modules =
      (builtins.attrValues self.nixosModules)
      ++ [
        ./_hardware-configuration-deck.nix

        ({...}: {
          mySystem = {
            hostName = "steamdeck";
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
              gaming = true;
              media = true;
              steamdeck = true;
            };

            hardware = {
              amd = true;
              bluetooth = true;
              steam = true;
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

          system.stateVersion = "25.05";
        })
      ];
  };
in {
  flake.nixosConfigurations.Deck = deck;
  flake.nixosConfigurations.deck = deck;
}
