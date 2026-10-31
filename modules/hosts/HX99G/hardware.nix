{
  config,
  lib,
  pkgs,
  ...
}:
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
    # zfs_2_4 is marked broken on linux_7_3, so pinned to the newest kernel it supports.
    kernelPackages = pkgs.linuxKernel.packages.linux_7_2;
    kernelParams = [ "hid_apple.fnmode=2" ];
    supportedFilesystems.zfs = true;
  };

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = lib.mkDefault true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.amdgpu.opencl.enable = true;
  hardware.amdgpu.overdrive.enable = true;

  services.lact.enable = true;

  # card numbers follow probe order, PCI ids do not
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", ENV{DEVTYPE}=="drm_minor", ATTR{device/vendor}=="0x1002", ATTR{device/device}=="0x1681", SYMLINK+="dri/igpu"
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", ENV{DEVTYPE}=="drm_minor", ATTR{device/vendor}=="0x1002", ATTR{device/device}=="0x73ff", SYMLINK+="dri/dgpu"
  '';

  # amd-pstate-epp pins EPP to performance under the performance governor, so this sets both.
  powerManagement.cpuFreqGovernor = "performance";

  fileSystems."/" = {
    device = "zroot/root";
    fsType = "zfs";
    neededForBoot = true;
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
    # vfat has no modes of its own; the default 0022 masks make the ESP and its random seed world-readable.
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
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

  swapDevices = [ { device = "/dev/disk/by-label/SWAP"; } ];

  boot.zswap = {
    enable = true;
    maxPoolPercent = 25;
  };

  environment.sessionVariables = {
    SDL_VIDEODRIVER = "wayland";
    PROTON_USE_NTSYNC = "1";
    RADV_PERFTEST = "gpl";
    DXVK_ASYNC = "1";
    # the first entry is the GPU the compositor renders on
    WLR_DRM_DEVICES = "/dev/dri/igpu:/dev/dri/dgpu";
  };
}
