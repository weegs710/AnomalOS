{inputs, ...}: {
  flake.nixosModules.fish = {
    config,
    pkgs,
    lib,
    ...
  }: let
    wrappedFish = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.fish;

    allPackages =
      config.environment.systemPackages
      ++ config.users.users.${config.mySystem.user.name}.packages;

    generatedCompletions = pkgs.buildEnv {
      name = "${config.mySystem.user.name}-fish-completions";
      paths = allPackages;
      pathsToLink = ["/share/fish"];
    };
  in {
    config = {
      users.users.${config.mySystem.user.name}.shell = wrappedFish;
      programs.fish.enable = true;

      hjem.users.${config.mySystem.user.name} = {
        xdg.config.files = let
          plugins = [
            pkgs.fishPlugins.fzf-fish
            pkgs.fishPlugins.z
            pkgs.fishPlugins.done
            pkgs.fishPlugins.colored-man-pages
            pkgs.fishPlugins.autopair-fish
            pkgs.fishPlugins.sponge
            pkgs.fishPlugins.forgit
          ];

          mkPluginFiles = plugin: let
            functionsDir = "${plugin}/share/fish/vendor_functions.d";
            functionFiles =
              if builtins.pathExists functionsDir
              then
                lib.listToAttrs (
                  map (fname: {
                    name = "fish/functions/${fname}";
                    value.source = "${functionsDir}/${fname}";
                  }) (builtins.attrNames (builtins.readDir functionsDir))
                )
              else {};
          in
            {
              "fish/conf.d/${plugin.pname}.fish" = {
                source = "${plugin}/share/fish/vendor_conf.d/${plugin.pname}.fish";
              };
            }
            // (
              if builtins.pathExists "${plugin}/share/fish/vendor_completions.d"
              then {
                "fish/completions/${plugin.pname}-completions" = {
                  source = "${plugin}/share/fish/vendor_completions.d";
                };
              }
              else {}
            )
            // functionFiles;
        in
          pkgs.lib.mkMerge ([
              {
                "fish/conf.d/functions.fish".text = ''
                  function kc-send -d "Send files to paired KDE Connect device"
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
                  end

                  function noct-r -d "Restart noctalia-shell"
                    pkill quickshell
                    tmux new -d noctalia-shell &
                  end
                '';

                "fish/conf.d/env.fish".text = ''
                  set -x PAGER bat
                  set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
                '';

                "fish/conf.d/aliases.fish".text = ''
                  alias repl "nix repl --expr 'import ~/dotfiles/repl.nix {}'"
                  alias evaltime "cd ~/dotfiles/ && hyperfine 'nix eval .#nixosConfigurations.Rig.config.system.build.toplevel --substituters \" \" --option eval-cache false --raw --read-only'"
                '';

                "fish/conf.d/greeting.fish".text = ''
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

                "fish/conf.d/completions-path.fish".text = ''
                  set -l generated_completions "${generatedCompletions}/share/fish/vendor_completions.d"
                  if test -d $generated_completions
                    if not contains $generated_completions $fish_complete_path
                      set -p fish_complete_path $generated_completions
                    end
                  end
                '';
              }
            ]
            ++ (map mkPluginFiles plugins));
      };
    };
  };
}
