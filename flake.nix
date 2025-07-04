{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nix-flatpak.url = "github:gmodena/nix-flatpak"; # unstable branch. Use github:gmodena/nix-flatpak/?ref=<tag> to pin releases.
    stylix.url = "github:danth/stylix/release-25.05";
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
