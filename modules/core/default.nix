{ lib, ... }:

{
  imports = [
    ./boot.nix
    ./networking.nix
    ./nix.nix
    ./users.nix
  ];
}
