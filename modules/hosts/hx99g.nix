{
  inputs,
  self,
  ...
}: let
  hx99g = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs;};
    modules =
      # Automatically import all nixosModules defined by flake-parts
      (builtins.attrValues self.nixosModules)
      ++ [
        inputs.lix-module.nixosModules.default
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
              yubikey = true;
              aiTooling = true;
              development = true;
              gaming = true;
              media = true;
            };

            hardware = {
              amd = true;
              bluetooth = true;
              steam = true;
            };
          };

          environment.variables.NH_FLAKE = "/home/weegs/dotfiles";

          nix.settings = {
            substituters = [
              "https://anomalos.cachix.org"
              "https://cache.lix.systems"
              "https://cache.nixos.org/"
            ];
            trusted-public-keys = [
              "anomalos.cachix.org-1:Rw01Lh1cj/LULRaPi6S145g1qrRzMr0hxvMTvQE0+Ms="
              "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            ];
          };

          system.stateVersion = "24.11";
        })
      ];
  };
in {
  flake.nixosConfigurations.HX99G = hx99g;
}
