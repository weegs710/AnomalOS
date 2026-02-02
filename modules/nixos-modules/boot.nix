{inputs, ...}: {
  flake.nixosModules.boot = {
    config,
    pkgs,
    ...
  }: {
    nixpkgs.overlays = [inputs.nix-cachyos-kernel.overlays.pinned];

    boot = {
      initrd.systemd.enable = true;
      plymouth.enable = true;
      kernelPackages = let
        customKernel = pkgs.cachyosKernels.linux-cachyos-latest-x86_64-v3.override {
          bbr3 = true;
        };
        basePackages = pkgs.linuxKernel.packagesFor customKernel;
      in
        basePackages.extend (self: super: {
          zfs_cachyos = pkgs.cachyosKernels.zfs-cachyos.override {
            kernel = customKernel;
          };
        });
      kernelParams = [
        "quiet"
        "hid_apple.fnmode=2"
        "amdgpu.dcdebugmask=0x610"
      ];
      consoleLogLevel = 0;
      initrd.verbose = false;
      supportedFilesystems.ntfs = true;
      supportedFilesystems.exfat = true;
      supportedFilesystems.zfs = true;
      zfs.package = pkgs.cachyosKernels.zfs-cachyos.override {
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
        "net.ipv4.ip_forward" = false;
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
