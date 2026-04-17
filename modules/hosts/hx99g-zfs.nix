{
  flake.modules.nixos.hx99g-zfs = {config, ...}: {
    services.sanoid.datasets = {
      "zroot/persist" = {
        useTemplate = ["critical"];
      };
      "zgames/games/roms" = {
        hourly = 6;
        daily = 3;
        weekly = 1;
        autoprune = true;
        autosnap = true;
      };
    };

    # /tmp is wiped on boot -- synced writes are wasted I/O for data that won't survive a reboot anyway.
    system.activationScripts.zfsTmpNoSync = ''
      ${config.boot.zfs.package}/bin/zfs set sync=disabled zroot/tmp
    '';
  };
}
