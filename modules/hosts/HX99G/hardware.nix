{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # Unmodified so it resolves to xddxdd's cached build -- any .override forces a local recompile.
  # See: https://github.com/xddxdd/nix-cachyos-kernel
  cachyPkgs = (pkgs.extend inputs.nix-cachyos-kernel.overlays.pinned).cachyosKernels;
in
{
  boot = {
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [
      "kvm-amd"
      "ntsync"
    ];
    extraModulePackages = [ ];
    zfs.devNodes = "/dev/disk/by-partuuid";
    kernelPackages = cachyPkgs.linuxPackages-cachyos-bore-x86_64-v3;
    kernelParams = [ "hid_apple.fnmode=2" ];
    supportedFilesystems.zfs = true;
    zfs.package = config.boot.kernelPackages.zfs_cachyos;
  };

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = lib.mkDefault true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.amdgpu.opencl.enable = true;
  hardware.amdgpu.overdrive.enable = true;

  services.lact.enable = true;

  fileSystems."/" = {
    device = "zroot/root";
    fsType = "zfs";
    neededForBoot = true;
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
  };
  fileSystems."/nix" = {
    device = "zroot/nix";
    fsType = "zfs";
    neededForBoot = true;
  };
  fileSystems."/tmp" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=5G"
      "mode=1777"
    ];
  };
  fileSystems."/persist" = {
    device = "zroot/persist";
    fsType = "zfs";
    neededForBoot = true;
  };
  fileSystems."/cache" = {
    device = "zroot/cache";
    fsType = "zfs";
    neededForBoot = true;
  };
  fileSystems."/mnt/games/1g1r" = {
    device = "zgames/games/roms";
    fsType = "zfs";
  };
  fileSystems."/mnt/games/SteamLibrary" = {
    device = "zgames/games/steam";
    fsType = "zfs";
  };
  fileSystems."/mnt/games/heroic" = {
    device = "zgames/games/heroic";
    fsType = "zfs";
  };

  swapDevices = [ ];

  zramSwap = {
    enable = true;
    memoryPercent = 25;
    algorithm = "zstd";
    priority = 100;
  };

  environment.sessionVariables = {
    SDL_VIDEODRIVER = "wayland";
    PROTON_USE_NTSYNC = "1";
    RADV_PERFTEST = "gpl";
    DXVK_ASYNC = "1";
  };
}
