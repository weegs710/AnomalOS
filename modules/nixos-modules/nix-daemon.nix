{
  flake.nixosModules.nix-daemon = {
    config,
    pkgs,
    ...
  }: {
    nix = {
      settings = {
        warn-dirty = false;
        trusted-users = [config.mySystem.user.name];
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        cores = 0;
        max-jobs = "auto";
      };

      optimise = {
        automatic = true;
        dates = ["00:00"];
      };
    };

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      curl
      git
      nh
      wget

      (pkgs.writeScriptBin "rig-up" ''
        #!/usr/bin/env nu

        def main [] {
            if not ("~/dotfiles/flake.nix" | path expand | path exists) {
                print $"(ansi red)Error: ~/dotfiles/flake.nix not found(ansi reset)"
                exit 1
            }

            cd ~/dotfiles/

            print $"(ansi blue)[1/3] Updating flake inputs...(ansi reset)"
            ^nix flake update
            if $env.LAST_EXIT_CODE != 0 {
                print $"(ansi red)✗ Flake update failed(ansi reset)"
                exit 1
            }
            print $"(ansi green)✓ Flake updated successfully(ansi reset)"

            print $"\n(ansi blue)[2/3] Testing Rig configuration...(ansi reset)"
            ^nh os test .#nixosConfigurations.Rig
            if $env.LAST_EXIT_CODE != 0 {
                print $"(ansi red)✗ Test failed! Configuration not applied.(ansi reset)"
                print $"(ansi yellow)Tip: Check the error messages above for details(ansi reset)"
                exit 1
            }
            print $"(ansi green)✓ Test completed successfully(ansi reset)"

            print $"\n(ansi blue)[3/3] Apply configuration?(ansi reset)"
            let response = input $"(ansi yellow)Test successful! Switch to new configuration? [y/N] (ansi reset)" | str trim | str downcase

            if ($response | str starts-with "y") {
                print $"(ansi blue)Switching to new configuration...(ansi reset)"
                ^nh os switch .#nixosConfigurations.Rig
                if $env.LAST_EXIT_CODE != 0 {
                    print $"(ansi red)✗ Switch failed(ansi reset)"
                    exit 1
                }
                print $"(ansi green)✓ Successfully switched to Rig configuration!(ansi reset)"
            } else {
                print $"(ansi yellow)Test not applied. You can run 'nrs-rig' later to switch.(ansi reset)"
            }
        }
      '')
    ];

    environment.shellAliases = {
      nfa = "cd ~/dotfiles/ && nix flake archive";
      recycle = "sudo nix-env --delete-generations +10 --profile /nix/var/nix/profiles/system && sudo nix-collect-garbage";
      update = "cd ~/dotfiles/ && nix flake update";
      closure = "nix path-info -Sh /run/current-system";
      shh = "tmux new -d 'env STEAM_FRAME_FORCE_CLOSE=1 steam -silent'";
      gui-up = "cp ~/.config/noctalia/gui-settings.json ~/dotfiles/modules/nixos-modules/noctalia-data/gui-settings.json";
      noct-up = "cd ~/dotfiles/ && nix flake update noctalia";
      nrs-rig = "cd ~/dotfiles/ && nh os switch .#nixosConfigurations.Rig";
      nrt-rig = "cd ~/dotfiles/ && nh os test .#nixosConfigurations.Rig";
    };
  };
}
