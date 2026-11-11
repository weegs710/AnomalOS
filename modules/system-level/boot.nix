{ pkgs, inputs, ... }:
{
  imports = [ inputs.bootvine.nixosModules.default ];

  # boot and shutdown show pending units and failures with their journal tail instead of scrolling lines
  services.bootvine = {
    enable = true;
    # Triglavian: hot red accents, chrome for done, light-magenta (nearest slot to mError) for failures; no cyan, yellow or green
    settings.colors = {
      header.total-time = "light-red";
      stages = {
        finished-time = "gray";
        failed-count = "light-magenta";
      };
      tree = {
        target = "light-red";
        current-stage = "light-red";
        reached-stage = "gray";
        running-marker = "light-red";
        finished-marker = "gray";
        failed-unit = "light-magenta";
      };
      timeline = {
        milestone = "light-red";
        finished = "gray";
        failed = "light-magenta";
        running = "light-red";
      };
      failures = {
        title = "light-magenta";
        unit = "light-magenta";
      };
      footer = {
        done = "gray";
        running = "light-red";
        failed = "light-magenta";
      };
      password = {
        frame = "light-red";
        rejected = "light-magenta";
      };
    };
  };

  console.font = "${pkgs.terminus_font}/share/consolefonts/ter-v18n.psf.gz";

  system.nixos.label = "";

  services.zfs.autoScrub.enable = true;

  # crashes still get a journal entry and backtrace, but no core is kept on disk
  systemd.coredump.settings.Coredump.Storage = "none";

  boot = {
    kernelParams = [ "quiet" ];
    # kernel errors from before bootvine takes the console still reach the screen
    consoleLogLevel = 3;
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
    kernelModules = [ "tcp_bbr" ];
    kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.conf.all.accept_redirects" = false;
      "net.ipv4.conf.default.accept_redirects" = false;
      "net.ipv4.conf.all.secure_redirects" = false;
      "net.ipv4.conf.default.secure_redirects" = false;
      "net.ipv6.conf.all.accept_redirects" = false;
      "net.ipv6.conf.default.accept_redirects" = false;
      "net.ipv4.conf.all.send_redirects" = false;
      "net.ipv4.tcp_syncookies" = true;
      "net.ipv4.tcp_rfc1337" = 1;
      "kernel.core_uses_pid" = true;
      "fs.suid_dumpable" = 0;
      "kernel.dmesg_restrict" = true;
      "kernel.kptr_restrict" = 2;
      "kernel.yama.ptrace_scope" = 1;
      "kernel.randomize_va_space" = 2;
    };
  };
}
