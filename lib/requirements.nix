# Extracts the storage a host's config demands, so the installer can refuse to format until the plan satisfies it.
host:
let
  outputs = import ../assemble.nix { };
  cfg = outputs.nixosConfigurations.${host}.config;
  lib = (import ../.tack).nixpkgs.lib;

  fsList = lib.mapAttrsToList (mountPoint: fs: fs // { inherit mountPoint; }) cfg.fileSystems;

  zfsMounts = builtins.filter (fs: fs.fsType == "zfs") fsList;
  datasets = lib.unique (map (fs: fs.device) zfsMounts);
  pools = lib.unique (map (d: builtins.head (lib.splitString "/" d)) datasets);

  byLabel = builtins.filter (fs: lib.hasPrefix "/dev/disk/by-label/" fs.device) fsList;
  # shallow paths first, so mounting in list order never buries a deeper mount
  mountOrder =
    a: b: (builtins.length (lib.splitString "/" a.mountPoint)) < (builtins.length (lib.splitString "/" b.mountPoint));
in
{
  inherit datasets pools;
  mountPoints = lib.sort (a: b: a < b) (map (fs: fs.mountPoint) fsList);
  zfsMounts = map (fs: { inherit (fs) mountPoint device neededForBoot; }) (lib.sort mountOrder zfsMounts);
  hostId = cfg.networking.hostId;
  devNodes = cfg.boot.zfs.devNodes;
  # the installer only knows cache.nixos.org, so without these every package from a private cache is rebuilt from source
  substituters = lib.unique cfg.nix.settings.substituters;
  trustedPublicKeys = lib.unique cfg.nix.settings.trusted-public-keys;
  labels = map (fs: {
    inherit (fs) mountPoint fsType;
    label = lib.removePrefix "/dev/disk/by-label/" fs.device;
  }) byLabel;
  tmpfs = map (fs: {
    inherit (fs) mountPoint options;
  }) (builtins.filter (fs: fs.fsType == "tmpfs") fsList);
  neededForBoot = map (fs: fs.mountPoint) (builtins.filter (fs: fs.neededForBoot) fsList);
  swap = map (s: s.device) cfg.swapDevices;
}
