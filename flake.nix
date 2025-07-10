{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    stylix.url = "github:danth/stylix/";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nix-flatpak,
      ...
    }@inputs:
    {
      nixosConfigurations.HX99G = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          nix-flatpak.nixosModules.nix-flatpak
          inputs.stylix.nixosModules.stylix
          ./configuration.nix
          inputs.home-manager.nixosModules.default
        ];
      };
    };
}
