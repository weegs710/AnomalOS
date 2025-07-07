{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak"; # unstable branch. Use github:gmodena/nix-flatpak/?ref=unstable to pin releases.
    stylix.url = "github:danth/stylix/";
  };

  outputs = {
    nixpkgs,
    nix-flatpak,
    ...
  } @ inputs: {
    nixosConfigurations.HX99G = nixpkgs.lib.nixosSystem {
      modules = [
        nix-flatpak.nixosModules.nix-flatpak
        inputs.stylix.nixosModules.stylix
        ./configuration.nix
      ];
    };
  };
}
