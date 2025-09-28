{ config, lib, pkgs, ... }:

{
  boot = {
    initrd.services.lvm.enable = true;
    plymouth.enable = true;
    kernelPackages = pkgs.linuxPackages_cachyos;
    kernelParams = [
      "quiet"
    ];
    consoleLogLevel = 0;
    initrd.verbose = false;

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # Security-focused kernel parameters
    kernel.sysctl = {
      # Network security
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

      # Kernel hardening
      "kernel.core_uses_pid" = true;
      "kernel.core_pattern" = "|/bin/false";
      "fs.suid_dumpable" = 0;
      "kernel.dmesg_restrict" = true;
      "kernel.kptr_restrict" = 2;
      "kernel.yama.ptrace_scope" = 1;
      "kernel.randomize_va_space" = 2;
    };
  };
}