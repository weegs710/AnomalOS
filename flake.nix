{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stylix.url = "github:danth/stylix/";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      ...
    }@inputs:
    {
      nixosConfigurations.HX99G = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          inputs.stylix.nixosModules.stylix
          ./configuration.nix
          inputs.home-manager.nixosModules.default
        ];
      };
    };
}
