{ pkgs, ... }:
{
  console.font = "${pkgs.terminus_font}/share/consolefonts/ter-v18n.psf.gz";

  system.nixos.label = "";

  services.zfs.autoScrub.enable = true;

  boot = {
    initrd.systemd.enable = true;
    kernelParams = [ "quiet" ];
    consoleLogLevel = 0;
    initrd.verbose = false;
    supportedFilesystems.ntfs = true;
    supportedFilesystems.exfat = true;
    zfs.forceImportRoot = false;
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        consoleMode = "max";
      };
      efi.canTouchEfiVariables = true;
    };
    # tcp_bbr3 and tcp_bbr export the same bpf kfunc, so loading one blocks the other.
    kernelModules = [ "tcp_bbr3" ];
    kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr3";
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
}
