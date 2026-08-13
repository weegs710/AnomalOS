{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystem.k8sLab;
  user = config.mySystem.user.name;

  nodeOpts = {
    options = {
      role = lib.mkOption {
        type = lib.types.enum [
          "control-plane"
          "worker"
          "lb"
        ];
        description = "Selects the guest package set: kube tooling, or haproxy for a load balancer.";
      };
      vcpu = lib.mkOption {
        type = lib.types.ints.positive;
        description = "vCPUs for this node.";
      };
      memoryMiB = lib.mkOption {
        type = lib.types.ints.positive;
        description = "RAM in MiB for this node.";
      };
      diskGiB = lib.mkOption {
        type = lib.types.ints.positive;
        default = 20;
        description = "Virtual size of the qcow2 overlay in GiB.";
      };
      ip = lib.mkOption {
        type = lib.types.str;
        description = "Static address on the lab network.";
      };
      mac = lib.mkOption {
        type = lib.types.str;
        description = "Fixed MAC, matched by netplan so guest NIC naming is irrelevant.";
      };
    };
  };

  writeFilesBlock =
    node:
    lib.concatStringsSep "\n" (
      lib.optionals (node.role != "lb") [
        "  - path: /etc/modules-load.d/k8s.conf"
        "    content: |"
        "      overlay"
        "      br_netfilter"
        "  - path: /etc/sysctl.d/99-k8s.conf"
        "    content: |"
        "      net.bridge.bridge-nf-call-iptables  = 1"
        "      net.bridge.bridge-nf-call-ip6tables = 1"
        "      net.ipv4.ip_forward                 = 1"
      ]
      ++ [
        "  - path: /etc/hosts"
        "    append: true"
        "    content: |"
      ]
      ++ lib.mapAttrsToList (n: v: "      ${v.ip} ${n}.${cfg.domain} ${n}") cfg.nodes
    );

  runcmdBlock =
    node:
    let
      common = [
        "swapoff -a"
        "sed -i '/[[:space:]]swap[[:space:]]/d' /etc/fstab"
        "systemctl disable --now ufw || true"
      ];
      runtime = [
        "modprobe overlay"
        "modprobe br_netfilter"
        "sysctl --system"
        "apt-get install -y containerd"
        "mkdir -p /etc/containerd"
        "containerd config default > /etc/containerd/config.toml"
        # kubelet and the runtime must agree on the cgroup driver or kubelet will not start
        "sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml"
        "systemctl restart containerd"
      ];
      kube = [
        "mkdir -p -m 755 /etc/apt/keyrings"
        "curl -fsSL ${cfg.k8sRepo}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg"
        "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] ${cfg.k8sRepo}/deb/ /' > /etc/apt/sources.list.d/kubernetes.list"
        "apt-get update"
        "apt-get install -y kubelet=${cfg.k8sPkgVersion} kubeadm=${cfg.k8sPkgVersion} kubectl=${cfg.k8sPkgVersion}"
        "apt-mark hold kubelet kubeadm kubectl"
      ];
      haproxy = [ "apt-get install -y haproxy" ];
    in
    lib.concatStringsSep "\n" (
      map (c: "  - ${c}") (
        common ++ lib.optionals (node.role != "lb") (runtime ++ kube) ++ lib.optionals (node.role == "lb") haproxy
      )
    );

  userData =
    name: node:
    pkgs.writeText "user-data-${name}" ''
      #cloud-config
      hostname: ${name}
      fqdn: ${name}.${cfg.domain}
      prefer_fqdn_over_hostname: false
      manage_etc_hosts: false

      users:
        - name: ${cfg.guestUser}
          sudo: ALL=(ALL) NOPASSWD:ALL
          shell: /bin/bash
          lock_passwd: true
          ssh_authorized_keys:
            - ${cfg.sshPublicKey}

      write_files:
      ${writeFilesBlock node}

      package_update: true
      packages:
        - apt-transport-https
        - ca-certificates
        - curl
        - gpg
        - qemu-guest-agent
        - yq

      runcmd:
      ${runcmdBlock node}
    '';

  metaData =
    name:
    pkgs.writeText "meta-data-${name}" ''
      instance-id: ${name}
      local-hostname: ${name}
    '';

  networkConfig =
    name: node:
    pkgs.writeText "network-config-${name}" ''
      version: 2
      ethernets:
        lab0:
          match:
            macaddress: "${node.mac}"
          set-name: lab0
          dhcp4: false
          addresses: [ ${node.ip}/24 ]
          routes:
            - to: default
              via: ${cfg.gateway}
          nameservers:
            addresses: [ ${cfg.gateway} ]
    '';

  networkXml = pkgs.writeText "network-${cfg.networkName}.xml" ''
    <network>
      <name>${cfg.networkName}</name>
      <bridge name='${cfg.bridge}'/>
      <forward mode='nat'/>
      <ip address='${cfg.gateway}' netmask='255.255.255.0'/>
    </network>
  '';

  seedFor =
    name: node:
    pkgs.runCommand "seed-${name}.iso" { nativeBuildInputs = [ pkgs.cloud-utils ]; } ''
      cloud-localds -N ${networkConfig name node} $out ${userData name node} ${metaData name}
    '';

  domainXml =
    name: node:
    pkgs.writeText "domain-${name}.xml" ''
      <domain type='kvm'>
        <name>${name}</name>
        <memory unit='MiB'>${toString node.memoryMiB}</memory>
        <vcpu>${toString node.vcpu}</vcpu>
        <os>
          <type arch='x86_64' machine='q35'>hvm</type>
          <boot dev='hd'/>
        </os>
        <features><acpi/><apic/></features>
        <cpu mode='host-passthrough'/>
        <clock offset='utc'/>
        <on_reboot>restart</on_reboot>
        <devices>
          <emulator>/run/libvirt/nix-emulators/qemu-kvm</emulator>
          <disk type='file' device='disk'>
            <driver name='qemu' type='qcow2' discard='unmap'/>
            <source file='${cfg.stateDir}/${name}.qcow2'/>
            <target dev='vda' bus='virtio'/>
          </disk>
          <disk type='file' device='cdrom'>
            <driver name='qemu' type='raw'/>
            <source file='${seedFor name node}'/>
            <target dev='sda' bus='sata'/>
            <readonly/>
          </disk>
          <interface type='network'>
            <mac address='${node.mac}'/>
            <source network='${cfg.networkName}'/>
            <model type='virtio'/>
          </interface>
          <console type='pty'><target type='serial' port='0'/></console>
          <channel type='unix'>
            <target type='virtio' name='org.qemu.guest_agent.0'/>
          </channel>
          <rng model='virtio'><backend model='random'>/dev/urandom</backend></rng>
        </devices>
      </domain>
    '';

  labUp = pkgs.writeShellApplication {
    name = "k8s-lab-up";
    runtimeInputs = [
      pkgs.libvirt
      pkgs.qemu_kvm
      pkgs.curl
      pkgs.coreutils
    ];
    text = ''
      base=${cfg.stateDir}/${cfg.baseImageName}
      mkdir -p ${cfg.stateDir}

      virsh --connect qemu:///system net-define ${networkXml} >/dev/null 2>&1 || true
      virsh --connect qemu:///system net-start ${cfg.networkName} >/dev/null 2>&1 || true
      virsh --connect qemu:///system net-autostart ${cfg.networkName} >/dev/null

      if [ ! -f "$base" ]; then
        curl -fsSL --retry 3 -o "$base.part" "${cfg.baseImageUrl}"
        mv "$base.part" "$base"
      fi

      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: node: ''
          if [ ! -f "${cfg.stateDir}/${name}.qcow2" ]; then
            qemu-img create -f qcow2 -F qcow2 -b "$base" \
              "${cfg.stateDir}/${name}.qcow2" ${toString node.diskGiB}G
          fi
          virsh --connect qemu:///system define ${domainXml name node} >/dev/null
        '') cfg.nodes
      )}

      echo "defined: ${lib.concatStringsSep " " (lib.attrNames cfg.nodes)}"
    '';
  };

  labDown = pkgs.writeShellApplication {
    name = "k8s-lab-down";
    runtimeInputs = [ pkgs.libvirt ];
    text = ''
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: _: ''
          virsh --connect qemu:///system destroy ${name} 2>/dev/null || true
          virsh --connect qemu:///system undefine ${name} 2>/dev/null || true
        '') cfg.nodes
      )}
      echo "undefined: ${lib.concatStringsSep " " (lib.attrNames cfg.nodes)}"
    '';
  };

  labReset = pkgs.writeShellApplication {
    name = "k8s-lab-reset";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: _: ''rm -f "${cfg.stateDir}/${name}.qcow2"'') cfg.nodes
      )}
      echo "overlays removed; run k8s-lab-up to rebuild from the base image"
    '';
  };
in
{
  options.mySystem.k8sLab = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = "lab.local";
      description = "DNS suffix written into every node's /etc/hosts.";
    };

    networkName = lib.mkOption {
      type = lib.types.str;
      default = "k8slab";
      description = "Dedicated libvirt network; separate from `default` so its DHCP range cannot collide with the static node addresses.";
    };

    bridge = lib.mkOption {
      type = lib.types.str;
      default = "virbr-k8s";
      description = "Bridge backing the lab network.";
    };

    gateway = lib.mkOption {
      type = lib.types.str;
      default = "192.168.126.1";
      description = "Gateway and resolver for the libvirt network above.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/libvirt/images";
      description = "Base image and per-node overlays; already covered by persist.nix.";
    };

    guestUser = lib.mkOption {
      type = lib.types.str;
      default = user;
      description = "Login created inside every guest, key-only.";
    };

    sshPublicKey = lib.mkOption {
      type = lib.types.str;
      # gitignored so the key stays out of the public remote; tack reads the working copy, so an untracked file still evals
      default = lib.optionalString (builtins.pathExists ./k8s-lab.pub) (
        lib.removeSuffix "\n" (builtins.readFile ./k8s-lab.pub)
      );
      description = "Public key injected into every guest; there is no password login.";
    };

    # LFS258 tracks Ubuntu 24.04
    baseImageUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img";
      description = "Ubuntu cloud image the guests are layered on.";
    };

    baseImageName = lib.mkOption {
      type = lib.types.str;
      default = "ubuntu-24.04-base.qcow2";
      description = "Filename the base image is cached under in stateDir.";
    };

    # matches the LFS258 course version and the CKA exam v1.35 series
    k8sRepo = lib.mkOption {
      type = lib.types.str;
      default = "https://pkgs.k8s.io/core:/stable:/v1.35";
      description = "pkgs.k8s.io base for the minor series.";
    };

    k8sPkgVersion = lib.mkOption {
      type = lib.types.str;
      default = "1.35.2-1.1";
      description = "Exact deb version installed and held on every node.";
    };

    nodes = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule nodeOpts);
      default = { };
      description = "Lab nodes; k8s-HA.nix adds the chapter 16 set on top.";
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.sshPublicKey != "";
        message = "mySystem.k8sLab.sshPublicKey is empty; the guests are key-only and would be unreachable.";
      }
    ];

    # sizes follow the LF lab doc minimums of 3vCPU/8G control plane and 1vCPU/1G worker
    mySystem.k8sLab.nodes = {
      cp = {
        role = "control-plane";
        vcpu = 3;
        memoryMiB = 8192;
        ip = "192.168.126.10";
        mac = "52:54:00:1a:35:10";
      };
      wrk1 = {
        role = "worker";
        vcpu = 2;
        memoryMiB = 4096;
        ip = "192.168.126.21";
        mac = "52:54:00:1a:35:21";
      };
      wrk2 = {
        role = "worker";
        vcpu = 2;
        memoryMiB = 4096;
        ip = "192.168.126.22";
        mac = "52:54:00:1a:35:22";
      };
    };

    virtualisation.libvirtd = {
      enable = true;
      qemu.package = pkgs.qemu_kvm;
      qemu.vhostUserPackages = [ pkgs.virtiofsd ];

      onBoot = "ignore";
      onShutdown = "shutdown";
    };

    networking.firewall.trustedInterfaces = [ cfg.bridge ];

    programs.virt-manager.enable = true;

    # libvirt's NSS resolves guests from DHCP leases, so it cannot see statically-addressed nodes
    networking.hosts = lib.mapAttrs' (
      name: node: lib.nameValuePair node.ip [ name "${name}.${cfg.domain}" ]
    ) cfg.nodes;


    users.users.${user}.extraGroups = [ "libvirtd" ];

    environment.systemPackages = with pkgs; [
      cloud-utils
      cri-tools
      etcd
      guestfs-tools
      k9s
      kubectl
      kubectx
      kubernetes-helm
      kustomize
      labDown
      labReset
      labUp
      stern
      virt-viewer
      yq-go
    ];
  };
}
