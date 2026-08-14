let
  np = (import ../../.tack).nixpkgs;
  cfg = import "${np}/nixos/lib/eval-config.nix" {
    system = "x86_64-linux";
    modules = [
      "${np}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
      (
        { pkgs, lib, config, ... }:
        {
          boot.initrd.availableKernelModules = [
            "9p"
            "9pnet_virtio"
          ];
          boot.kernelModules = [
            "9p"
            "9pnet_virtio"
          ];
          environment.systemPackages = with pkgs; [
            jq
            git
          ];
          nix.settings.experimental-features = [
            "nix-command"
            "flakes"
          ];

          # headless, so output exists only if it reaches the serial console
          boot.kernelParams = [
            "console=tty0"
            "console=ttyS0,115200n8"
          ];
          boot.loader.timeout = lib.mkForce 0;

          # scenarios arrive over the share so a new test costs no ISO rebuild
          systemd.services.harness = {
            description = "anomalOS install harness";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              StandardOutput = "journal+console";
              StandardError = "journal+console";
            };
            # the whole system path, so a scenario is not limited to a hand-picked tool list
            path = [ config.system.path ];
            script = ''
              mkdir -p /harness
              if ! mount -t 9p -o trans=virtio,version=9p2000.L,msize=262144 harness /harness; then
                echo "HARNESS: no 9p share, dropping to shell"
                exit 0
              fi
              if [ ! -x /harness/run.sh ]; then
                echo "HARNESS: /harness/run.sh missing or not executable"
                exit 0
              fi
              echo "HARNESS: START"
              /harness/run.sh; rc=$?
              echo "HARNESS: EXIT $rc"
              echo "HARNESS: DONE"
            '';
          };
        }
      )
    ];
  };
in
cfg
