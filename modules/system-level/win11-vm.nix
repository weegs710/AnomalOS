{
  config,
  lib,
  pkgs,
  only,
  utils,
  ...
}:
let
  cfg = config.mySystem.win11Vm;
  user = config.mySystem.user.name;

  diskPath = "${cfg.stateDir}/${cfg.name}.qcow2";

  isoDisk = lib.optionalString (cfg.isoPath != null) ''
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='${cfg.isoPath}'/>
      <target dev='sdb' bus='sata'/>
      <readonly/>
      <boot order='1'/>
    </disk>
  '';

  # bochs gives Windows a GOP framebuffer it can switch modes on; the vga model rendered a 1280x800 desktop smeared across a 2560-wide buffer.
  domainXml = pkgs.writeText "domain-${cfg.name}.xml" ''
    <domain type='kvm'>
      <name>${cfg.name}</name>
      <uuid>${cfg.uuid}</uuid>
      <memory unit='MiB'>${toString cfg.memoryMiB}</memory>
      <vcpu>${toString cfg.vcpu}</vcpu>
      <os firmware='efi'>
        <type arch='x86_64' machine='q35'>hvm</type>
        <firmware>
          <feature enabled='yes' name='secure-boot'/>
          <feature enabled='no' name='enrolled-keys'/>
        </firmware>
      </os>
      <features><acpi/><apic/><smm state='on'/></features>
      <cpu mode='host-passthrough'/>
      <clock offset='localtime'/>
      <on_reboot>restart</on_reboot>
      <devices>
        <emulator>/run/libvirt/nix-emulators/qemu-kvm</emulator>
        <disk type='file' device='disk'>
          <driver name='qemu' type='qcow2' discard='unmap'/>
          <source file='${diskPath}'/>
          <target dev='sda' bus='sata'/>
          <boot order='2'/>
        </disk>
        ${isoDisk}
        <interface type='network'>
          <mac address='${cfg.mac}'/>
          <source network='default'/>
          <model type='e1000e'/>
        </interface>
        <tpm model='tpm-crb'>
          <backend type='emulator' version='2.0'/>
        </tpm>
        <graphics type='spice'>
          <listen type='none'/>
        </graphics>
        <video>
          <model type='bochs' vram='16384' heads='1' primary='yes'>
            <resolution x='${toString cfg.resolution.x}' y='${toString cfg.resolution.y}'/>
          </model>
        </video>
        <sound model='ich9'><audio id='1'/></sound>
        <audio id='1' type='spice'/>
        <input type='tablet' bus='usb'/>
      </devices>
    </domain>
  '';

  vmUp = pkgs.writeShellApplication {
    name = "win11-vm-up";
    runtimeInputs = [
      pkgs.libvirt
      pkgs.qemu_kvm
    ];
    text = ''
      [ -f ${diskPath} ] || qemu-img create -f qcow2 ${diskPath} ${toString cfg.diskGiB}G
      virsh --connect qemu:///system define ${domainXml}
      echo "defined ${cfg.name}, not started: virsh --connect qemu:///system start ${cfg.name}"
    '';
  };

  vmDown = pkgs.writeShellApplication {
    name = "win11-vm-down";
    runtimeInputs = [ pkgs.libvirt ];
    text = ''
      virsh --connect qemu:///system destroy ${cfg.name} 2>/dev/null || true
      virsh --connect qemu:///system undefine ${cfg.name} --keep-nvram --keep-tpm
      echo "undefined ${cfg.name}; disk, NVRAM and TPM state kept"
    '';
  };

  vmReset = pkgs.writeShellApplication {
    name = "win11-vm-reset";
    runtimeInputs = [
      pkgs.libvirt
      pkgs.coreutils
    ];
    text = ''
      if [ "$(virsh --connect qemu:///system domstate ${cfg.name} 2>/dev/null || true)" = "running" ]; then
        echo "${cfg.name} is running; stop it first" >&2
        exit 1
      fi
      virsh --connect qemu:///system undefine ${cfg.name} --nvram --tpm 2>/dev/null || true
      rm -f ${diskPath}
      echo "disk, NVRAM and TPM state removed; run win11-vm-up for a factory-fresh VM"
    '';
  };

  # Waiting here keeps the VT idle while the VM is off, instead of the unit crash-looping through a PAM session every few seconds.
  # -s is what lets Ctrl+Alt+Fn leave the VT again; cage ignores VT switches without it.
  kioskRun = pkgs.writeShellApplication {
    name = "win11-vm-kiosk-run";
    runtimeInputs = [
      pkgs.cage
      pkgs.libvirt
      pkgs.virt-viewer
    ];
    text = ''
      until [ "$(virsh --connect qemu:///system domstate ${cfg.name} 2>/dev/null || true)" = "running" ]; do
        sleep 2
      done
      exec cage -s -- virt-viewer --attach --full-screen --auto-resize never --connect qemu:///system ${cfg.name}
    '';
  };

  kioskTty = "tty${toString cfg.kiosk.vt}";
in
{
  options.mySystem.win11Vm = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "win11-test";
      description = "libvirt domain name and disk basename.";
    };

    uuid = lib.mkOption {
      type = lib.types.str;
      default = "539ff3c6-ce37-4fdf-bf04-f1b75c6f1619";
      description = "Fixed so a second define updates the domain instead of failing on a name collision.";
    };

    mac = lib.mkOption {
      type = lib.types.str;
      default = "52:54:00:1a:36:01";
      description = "Fixed MAC, outside the k8s lab's 52:54:00:1a:35:xx range.";
    };

    memoryMiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 8192;
      description = "Guest RAM in MiB.";
    };

    vcpu = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4;
      description = "Guest vCPUs.";
    };

    diskGiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 80;
      description = "Virtual size of the system disk in GiB.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/libvirt/images";
      description = "Where the system disk lives; root-owned, so win11-vm-up needs sudo.";
    };

    isoPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Windows installer ISO, fetched by hand because nix cannot download it; null leaves no CD attached.";
    };

    resolution = {
      x = lib.mkOption {
        type = lib.types.ints.positive;
        default = 2560;
        description = "Guest display width in pixels. Windows still has to be switched to it once under Settings > Display, after which it persists.";
      };

      y = lib.mkOption {
        type = lib.types.ints.positive;
        default = 1440;
        description = "Guest display height in pixels.";
      };
    };

    kiosk = {
      enable = lib.mkEnableOption "a fullscreen viewer for the VM on its own VT, started at boot and waiting for the VM to run";

      vt = lib.mkOption {
        type = lib.types.ints.between 7 12;
        default = 7;
        description = "VT the viewer owns. Above logind's NAutoVTs (6) so no getty is spawned there, and 12 is the highest VT cage can switch away from.";
      };
    };
  };

  config = only.gate { tags = [ "lab" ]; } {
    virtualisation.libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };

    users.users.${user}.extraGroups = [ "libvirtd" ];

    environment.systemPackages = [
      pkgs.virt-viewer
      vmDown
      vmReset
      vmUp
    ];

    # Modeled on nixpkgs' services.cage, which is hardwired to tty1 and would fight greetd for it.
    systemd.services.win11-vm-kiosk = lib.mkIf cfg.kiosk.enable {
      description = "Fullscreen ${cfg.name} viewer on ${kioskTty}";
      after = [
        "systemd-user-sessions.service"
        "systemd-logind.service"
        "libvirtd.service"
      ];
      wants = [ "systemd-logind.service" ];
      wantedBy = [ "graphical.target" ];
      # A rebuild must not tear down the viewer of a running VM.
      restartIfChanged = false;
      unitConfig = {
        ConditionPathExists = "/dev/${kioskTty}";
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        ExecStart = lib.getExe kioskRun;
        User = user;
        Restart = "always";
        RestartSec = 2;
        IgnoreSIGPIPE = "no";
        UtmpIdentifier = "%n";
        UtmpMode = "user";
        TTYPath = "/dev/${kioskTty}";
        TTYReset = "yes";
        TTYVHangup = "yes";
        TTYVTDisallocate = "yes";
        StandardInput = "tty-fail";
        StandardOutput = "journal";
        StandardError = "journal";
        PAMName = "win11-kiosk";
      };
    };

    # Same stack as the nixpkgs cage service: pam_systemd is what makes this a logind session on the VT, which libseat needs.
    security.pam.services.win11-kiosk = lib.mkIf cfg.kiosk.enable {
      useDefaultRules = false;
      rules = {
        auth = utils.pam.autoOrderRules [
          {
            name = "unix";
            control = "required";
            modulePath = config.security.pam.pam_unixModulePath;
            settings.nullok = true;
          }
        ];
        account = utils.pam.autoOrderRules [
          {
            name = "unix";
            control = "required";
            modulePath = config.security.pam.pam_unixModulePath;
          }
        ];
        session = utils.pam.autoOrderRules [
          {
            name = "unix";
            control = "required";
            modulePath = config.security.pam.pam_unixModulePath;
          }
          {
            name = "env";
            control = "required";
            modulePath = "${config.security.pam.package}/lib/security/pam_env.so";
            settings.conffile = "/etc/pam/environment";
            settings.readenv = 0;
          }
          {
            name = "systemd";
            control = "required";
            modulePath = "${config.systemd.package}/lib/security/pam_systemd.so";
          }
        ];
      };
    };
  };
}
