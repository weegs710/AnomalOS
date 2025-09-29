{
  description = "Modular NixOS Configuration with Optional Components";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stylix.url = "github:danth/stylix/";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cachyos.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  };

  outputs = { nixpkgs, cachyos, ... }@inputs: {
    # Four essential configurations covering all use cases
    nixosConfigurations = {
      # Full system with all features (YubiKey + Claude Code + Gaming + Desktop)
      Rig = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          inputs.stylix.nixosModules.stylix
          inputs.cachyos.nixosModules.default
          ./configuration.nix
        ];
      };

      # No YubiKey (Claude Code + Gaming + Desktop)
      Hack = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          inputs.stylix.nixosModules.stylix
          inputs.cachyos.nixosModules.default
          ./configuration.nix
          {
            mySystem.features.yubikey = nixpkgs.lib.mkForce false;
          }
        ];
      };

      # No Claude Code (YubiKey + Gaming + Desktop)
      Guard = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          inputs.stylix.nixosModules.stylix
          inputs.cachyos.nixosModules.default
          ./configuration.nix
          {
            mySystem.features.claudeCode = nixpkgs.lib.mkForce false;
          }
        ];
      };

      # Minimal system (Gaming + Desktop only, no YubiKey or Claude Code)
      Stub = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          inputs.stylix.nixosModules.stylix
          inputs.cachyos.nixosModules.default
          ./configuration.nix
          {
            mySystem.features = {
              yubikey = nixpkgs.lib.mkForce false;
              claudeCode = nixpkgs.lib.mkForce false;
            };
          }
        ];
      };
    };

    # Development shell for working on this configuration
    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      buildInputs = with nixpkgs.legacyPackages.x86_64-linux; [
        nixfmt-rfc-style
        nil
        git
      ];
    };
  };
}