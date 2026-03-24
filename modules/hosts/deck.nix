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
              "https://anomalos.cachix.org"
              "https://cache.nixos.org/"
            ];
            trusted-public-keys = [
              "anomalos.cachix.org-1:Rw01Lh1cj/LULRaPi6S145g1qrRzMr0hxvMTvQE0+Ms="
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
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
