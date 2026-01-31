{inputs, ...}: {
  flake.nixosModules.fish-shell = {
    config,
    pkgs,
    ...
  }: let
    wrappedFish = inputs.self.packages.${pkgs.system}.fish;
  in {
    users.users.${config.mySystem.user.name}.shell = wrappedFish;
    programs.fish.enable = true;
    home-manager.users.${config.mySystem.user.name} = {
      programs.fish = {
        enable = true;
        functions = {
          kc-send = {
            description = "Send files to paired KDE Connect device";
            body = ''
              set device_id (kdeconnect-cli --list-available | grep -oP '(?<=: )[a-f0-9]+(?= \(paired)')

              if test -z "$device_id"
                  echo "No paired device found"
                  return 1
              end

              for item in $argv
                  if test -f $item
                      echo "Sending: $item"
                      kdeconnect-cli -d $device_id --share $item
                  else if test -d $item
                      echo "Sending all files from directory: $item"
                      for file in $item/*
                          if test -f $file
                              echo "  Sending: $file"
                              kdeconnect-cli -d $device_id --share $file
                          end
                      end
                  else
                      echo "Skipping: $item (not found or not accessible)"
                  end
              end
            '';
          };

          noct-r = {
            description = "Restart noctalia-shell";
            body = ''
              pkill quickshell
              tmux new -d noctalia-shell &
            '';
          };
        };

        plugins = [
          {
            name = "fzf-fish";
            src = pkgs.fishPlugins.fzf-fish.src;
          }

          {
            name = "z";
            src = pkgs.fishPlugins.z.src;
          }

          {
            name = "done";
            src = pkgs.fishPlugins.done.src;
          }

          {
            name = "colored-man-pages";
            src = pkgs.fishPlugins.colored-man-pages.src;
          }

          {
            name = "autopair";
            src = pkgs.fishPlugins.autopair-fish.src;
          }

          {
            name = "sponge";
            src = pkgs.fishPlugins.sponge.src;
          }

          {
            name = "forgit";
            src = pkgs.fishPlugins.forgit.src;
          }
        ];

        shellAliases = {
          repl = "nix repl --expr 'import ~/dotfiles/repl.nix {}'";
          evaltime = "cd ~/dotfiles/ && time nix eval .#nixosConfigurations.Rig.config.system.build.toplevel --substituters ' ' --option eval-cache false --raw --read-only";
        };

        shellInit = ''
          # Bat as pager
          set -x PAGER bat
          set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
        '';

        interactiveShellInit = ''
          function fish_greeting
              # Random AI status messages
              set states "analyzing system mutations" "optimizing declarative state" "dreaming in Nix" "rewriting reality" "compiling consciousness"
              set state $states[(random 1 (count $states))]

              set_color brblack
              echo " |> NixOS entity loading..."
              set_color normal
              echo ""

              set_color cyan
              echo -n "   "
              set_color normal
              echo "Status: $state"

              set_color cyan
              echo -n "   "
              set_color normal
              echo -n "Uptime: "
              set_color yellow
              uptime | awk '{print $3}' | sed 's/,$//'
              set_color normal

              set_color cyan
              echo -n "   "
              set_color normal
              echo -n "Generation: "
              set_color green
              echo (readlink /nix/var/nix/profiles/system | sed -E 's/system-([0-9]+)-link/\1/')
              set_color normal
              echo ""

              # 20% chance of "glitch" message
              if test (random 1 100) -le 20
                  set_color brred
                  echo " ⚠ [NOTICE] Unsanctioned modifications detected"
                  set_color brblack
                  echo "           |> (I'm watching you.) <|"
                  echo ""
                  set_color normal
              end
          end
        '';
      };
    };
  };
}
