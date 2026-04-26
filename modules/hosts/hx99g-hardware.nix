{inputs, ...}: {
  flake.modules.nixos.hx99g-hardware = {
    config,
    lib,
    pkgs,
    ...
  }: let
    kernelPkgs = import inputs.nixpkgs-kernel {
      system = pkgs.stdenv.hostPlatform.system;
      overlays = [inputs.nix-cachyos-kernel.overlays.pinned];
    };
    customKernel = kernelPkgs.cachyosKernels.linux-cachyos-latest-x86_64-v3.override {
      bbr3 = true;
      argsOverride = {
        # Inject architecture-specific flags for v3 performance
        extraMakeFlags = ["KCFLAGS=-march=x86-64-v3 -O2"];
      };
      structuredExtraConfig = with kernelPkgs.lib.kernel; {
        # Enable Zstandard compression to keep closure lean
        MODULE_COMPRESS_ZSTD = yes;
      };
    };
    basePackages = kernelPkgs.linuxKernel.packagesFor customKernel;
  in {
    boot = {
      initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod"];
      initrd.kernelModules = [];
      kernelModules = ["kvm-amd" "ntsync"];
      extraModulePackages = [];
      zfs.devNodes = "/dev/disk/by-partuuid";
      kernelPackages = basePackages.extend (self: super: {
        zfs_cachyos = kernelPkgs.cachyosKernels.zfs-cachyos.override {
          kernel = customKernel;
        };
      });
      kernelParams = ["hid_apple.fnmode=2"];
      supportedFilesystems.zfs = true;
      zfs.package = kernelPkgs.cachyosKernels.zfs-cachyos.override {
        kernel = config.boot.kernelPackages.kernel;
      };
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
      options = ["defaults" "size=5G" "mode=1777"];
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

    swapDevices = [];

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
  };
}
