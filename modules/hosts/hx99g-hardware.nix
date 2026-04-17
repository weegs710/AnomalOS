{
  flake.modules.nixos.hx99g-hardware = {
    config,
    lib,
    ...
  }: {
    boot = {
      initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod"];
      initrd.kernelModules = [];
      kernelModules = ["kvm-amd"];
      extraModulePackages = [];
      zfs.devNodes = "/dev/disk/by-partuuid";
    };

    networking.useDHCP = lib.mkDefault true;
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.enableRedistributableFirmware = lib.mkDefault true;
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    fileSystems."/" = {device = "zroot/root"; fsType = "zfs"; neededForBoot = true;};
    fileSystems."/boot" = {device = "/dev/disk/by-label/NIXBOOT"; fsType = "vfat";};
    fileSystems."/nix" = {device = "zroot/nix"; fsType = "zfs"; neededForBoot = true;};
    fileSystems."/tmp" = {device = "zroot/tmp"; fsType = "zfs";};
    fileSystems."/persist" = {device = "zroot/persist"; fsType = "zfs"; neededForBoot = true;};
    fileSystems."/cache" = {device = "zroot/cache"; fsType = "zfs"; neededForBoot = true;};
    fileSystems."/mnt/games/1g1r" = {device = "zgames/games/roms"; fsType = "zfs";};
    fileSystems."/mnt/games/SteamLibrary" = {device = "zgames/games/steam"; fsType = "zfs";};
    fileSystems."/mnt/games/heroic" = {device = "zgames/games/heroic"; fsType = "zfs";};

    swapDevices = [];

    zramSwap = {
      enable = true;
      memoryPercent = 25;
      algorithm = "zstd";
      priority = 100;
    };
  };
}
