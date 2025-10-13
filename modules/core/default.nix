# Core System Modules
#
# This module aggregates essential system configuration:
#   - boot.nix: Bootloader and kernel configuration
#   - networking.nix: Network settings and hostname
#   - nix.nix: Nix package manager settings, garbage collection, caches
#   - users.nix: User account configuration
#
# These modules are always imported regardless of feature flags.

{ lib, ... }:

{
  imports = [
    ./boot.nix
    ./networking.nix
    ./nix.nix
    ./users.nix
  ];
}
