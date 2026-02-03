{
  description = "Modular NixOS Configuration with Optional Components";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.6.0";
    helium = {
      url = "github:FKouhai/helium2nix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-kernel = {
      url = "github:NixOS/nixpkgs/cb369ef2efd432b3cdf8622b0ffc0a97a02f3137";
    };
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{flake-parts, ...}: let
    inherit (inputs.nixpkgs.lib.fileset) toList fileFilter;
    import-tree = path:
      toList (fileFilter (file: file.hasExt "nix" && !(inputs.nixpkgs.lib.hasPrefix "_" file.name)) path);
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      imports = import-tree ./modules;
    };
}
