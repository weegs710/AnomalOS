# Stub — replace with nixos-generate-config output after booting the installer.
# Adjust the ZFS pool name and boot partition label to match the actual install.
{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot = {
    initrd.availableKernelModules = ["nvme" "xhci_pci" "usbhid" "usb_storage" "sd_mod" "sdhci_pci"];
    initrd.kernelModules = ["amdgpu"];
    kernelModules = [];
    extraModulePackages = [];
  };

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  boot.zfs.devNodes = "/dev/disk/by-partuuid";

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
    device = "zroot/tmp";
    fsType = "zfs";
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

  swapDevices = [];

  zramSwap = {
    enable = true;
    memoryPercent = 25;
    algorithm = "zstd";
    priority = 100;
  };
}
