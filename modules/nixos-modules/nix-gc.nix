{
  flake.nixosModules.nix-gc = {pkgs, ...}: {
    systemd.services.nix-gc-custom = {
      description = "Nix Garbage Collector (preserves generation 1)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeScript "nix-gc-custom" ''
          #!${pkgs.nushell}/bin/nu

          let profile = "/nix/var/nix/profiles/system"
          let cutoff_date = (^${pkgs.coreutils}/bin/date -d '90 days ago' +%s | str trim | into int)

          (^${pkgs.nix}/bin/nix-env --list-generations --profile $profile
            | lines
            | each { |line|
                let parts = ($line | split row -r '\s+')
                let gen = ($parts | get 0)
                let date_str = ($parts | get 1)
                let time_str = ($parts | get 2)
                try { $gen | into int } catch { return }
                if $gen == "1" { return }
                let gen_date = (^${pkgs.coreutils}/bin/date -d $"($date_str) ($time_str)" +%s | str trim | into int)
                if $gen_date < $cutoff_date {
                  print $"Deleting generation ($gen) from ($date_str) ($time_str)"
                  ^${pkgs.nix}/bin/nix-env --delete-generations $gen --profile $profile
                }
            })
          ^${pkgs.nix}/bin/nix-collect-garbage

          print "GC complete. Generation 1 preserved."
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
