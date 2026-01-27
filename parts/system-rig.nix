{ inputs, ... }:

{
  # Define the Rig NixOS system configuration
  # Features are imported and applied via configuration.nix

  flake.nixosConfigurations.Rig = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # Agenix secrets management
      inputs.agenix.nixosModules.default

      # Hardware configuration
      ../hardware-configuration-zfs.nix
      ../features/security/secrets.nix

      # Main system configuration (imports all features)
      ../configuration.nix
    ];
  };
}
