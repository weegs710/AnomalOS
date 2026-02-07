{...}: {
  flake.nixosModules.nix-gc = {pkgs, ...}: {
    systemd.services.nix-gc-custom = {
      description = "Nix Garbage Collector (preserves generation 1)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "nix-gc-custom" ''
          set -e

          profile=/nix/var/nix/profiles/system
          cutoff_date=$(date -d '90 days ago' +%s)

          ${pkgs.nix}/bin/nix-env --list-generations --profile $profile | while read gen date time rest; do
            [[ "$gen" =~ ^[0-9]+$ ]] || continue
            [ "$gen" = "1" ] && continue

            gen_date=$(date -d "$date $time" +%s)
            if [ "$gen_date" -lt "$cutoff_date" ]; then
              echo "Deleting generation $gen (from $date $time)"
              ${pkgs.nix}/bin/nix-env --delete-generations "$gen" --profile $profile
            fi
          done

          ${pkgs.nix}/bin/nix-collect-garbage

          echo "GC complete. Generation 1 preserved."
        '';
      };
    };

    systemd.timers.nix-gc-custom = {
      description = "Timer for Nix GC (preserves generation 1)";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
  };
}
