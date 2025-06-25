{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nix-flatpak.url = "github:gmodena/nix-flatpak"; # unstable branch. Use github:gmodena/nix-flatpak/?ref=<tag> to pin releases.
  };

  outputs = {nix-flatpak, ...}: {
    nixosConfigurations.HX99G = nixpkgs.lib.nixosSystem {
      modules = [
        nix-flatpak.nixosModules.nix-flatpak

        ./configuration.nix
      ];
    };
  };
}
