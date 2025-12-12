# Core System Modules
#
# This module aggregates essential system configuration:
#   - boot.nix: Bootloader and kernel configuration
#   - networking.nix: Network settings and hostname
#   - nix.nix: Nix package manager settings, garbage collection, caches
#   - users.nix: User account configuration
#   - zfs-snapshots.nix: Automatic ZFS snapshot management with sanoid
#
# These modules are always imported regardless of feature flags.
{lib, ...}: {
  imports = [
    ./boot.nix
    ./networking.nix
    ./nix.nix
    ./users.nix
    ./zfs-snapshots.nix
  ];
}
