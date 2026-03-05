{inputs, ...}: {
  flake.nixosModules.boot = {
    config,
    pkgs,
    ...
  }: let
    kernelPkgs = import inputs.nixpkgs-kernel {
      system = pkgs.stdenv.system;
      overlays = [inputs.nix-cachyos-kernel.overlays.pinned];
    };
  in {
    boot = {
      tmp.cleanOnBoot = true;
      initrd.systemd.enable = true;
      plymouth.enable = true;
      kernelPackages = let
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
          # ------------------------------------------------
        };
        basePackages = kernelPkgs.linuxKernel.packagesFor customKernel;
      in
        basePackages.extend (self: super: {
          zfs_cachyos = kernelPkgs.cachyosKernels.zfs-cachyos.override {
            kernel = customKernel;
          };
        });

      kernelParams = [
        "quiet"
        "hid_apple.fnmode=2"
      ];
      consoleLogLevel = 0;
      initrd.verbose = false;
      supportedFilesystems.ntfs = true;
      supportedFilesystems.exfat = true;
      supportedFilesystems.zfs = true;
      zfs.package = kernelPkgs.cachyosKernels.zfs-cachyos.override {
        kernel = config.boot.kernelPackages.kernel;
      };
      loader = {
        systemd-boot = {
          enable = true;
          configurationLimit = 10;
        };
        efi.canTouchEfiVariables = true;
      };

      kernel.sysctl = {
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
        "net.ipv4.conf.all.forwarding" = false;
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.conf.all.accept_redirects" = false;
        "net.ipv4.conf.default.accept_redirects" = false;
        "net.ipv4.conf.all.secure_redirects" = false;
        "net.ipv4.conf.default.secure_redirects" = false;
        "net.ipv6.conf.all.accept_redirects" = false;
        "net.ipv6.conf.default.accept_redirects" = false;
        "net.ipv4.conf.all.send_redirects" = false;
        "net.ipv6.conf.all.forwarding" = false;
        "net.ipv4.tcp_syncookies" = true;
        "net.ipv4.tcp_rfc1337" = 1;
        "kernel.core_uses_pid" = true;
        "kernel.core_pattern" = "|/bin/false";
        "fs.suid_dumpable" = 0;
        "kernel.dmesg_restrict" = true;
        "kernel.kptr_restrict" = 2;
        "kernel.yama.ptrace_scope" = 1;
        "kernel.randomize_va_space" = 2;
      };
    };
  };
}
