{
  flake.nixosModules.wlr-which-key = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    homeDir = config.users.users.${username}.home;
    yamlFormat = pkgs.formats.yaml {};

    btopCmd = "hyprctl dispatch exec '[size 1600 900; move 531 262; float; opacity 1.0 override 1.0 override 1.0 override] ghostty --title=btop -e btop'";
    euphonicaCmd = "euphonica";
    terminalCmd = "ghostty --title=ghostty";
    fileManagerCmd = "hyprctl dispatch exec '[size 1600 900; move 531 262; float; opacity 1.0 override 1.0 override 1.0 override] ghostty -e superfile'";

    shotSaveScript = pkgs.writeTextFile {
      name = "shot-save.nu";
      executable = true;
      text = ''
        def main [tmp_file: string] {
          let shots_dir = ([$env.HOME, "Pictures", "shots"] | path join)
          mkdir $shots_dir
          let name = (input "Shot name: " | str trim | str replace --all "'" "" | str replace --all "/" "" | str replace --regex '(?i)\.webp$' "")
          if $name == "" {
            ^rm -f $tmp_file
            return
          }
          let outfile = ([$shots_dir, $"($name).webp"] | path join)
          ^cwebp -lossless $tmp_file -o $outfile
          ^rm -f $tmp_file
        }
      '';
    };

    clipStartScript = pkgs.writeTextFile {
      name = "clip-start.nu";
      executable = true;
      text = ''
        def main [mode: string, region?: string] {
          let tmp_file = "/tmp/gsr_clip.mp4"
          let capture = if $mode == "region" { $region } else { $mode }
          ^bash -c $"setsid gpu-screen-recorder -w '($capture)' -f 60 -a default_output -c mp4 -o '($tmp_file)' >/tmp/gsr.log 2>&1 & echo $! > /tmp/gsr.pid"
        }
      '';
    };

    clipSaveScript = pkgs.writeTextFile {
      name = "clip-save.nu";
      executable = true;
      text = ''
        def main [] {
          let tmp_file = "/tmp/gsr_clip.mp4"
          if not ($tmp_file | path exists) { return }
          let clips_dir = ([$env.HOME, "Videos", "clips"] | path join)
          mkdir $clips_dir
          let name = (input "Clip name: " | str trim | str replace --all "'" "" | str replace --all "/" "" | str replace --regex '(?i)\.mp4$' "")
          if $name == "" {
            ^rm -f $tmp_file
            return
          }
          let outfile = ([$clips_dir, $"($name).mp4"] | path join)
          ^mv $tmp_file $outfile
        }
      '';
    };

    shotRegionSaveCmd = ''fn=/tmp/wkshot_$$.png && hyprshot -m region -z --raw > $fn && ghostty --title=name-shot -e nu ${shotSaveScript} $fn'';
    shotWindowSaveCmd = ''fn=/tmp/wkshot_$$.png && hyprshot -m window -z --raw > $fn && ghostty --title=name-shot -e nu ${shotSaveScript} $fn'';
    shotScreenSaveCmd = ''fn=/tmp/wkshot_$$.png && hyprshot -m output -z --raw > $fn && ghostty --title=name-shot -e nu ${shotSaveScript} $fn'';
    clipRegionCmd = ''region=$(slurp -f "%wx%h+%x+%y") && nu ${clipStartScript} region "$region"'';
    clipScreenCmd = ''nu ${clipStartScript} screen'';
    clipWindowCmd = ''nu ${clipStartScript} focused'';
    stopRecordCmd = ''bash -c 'pid=$(cat /tmp/gsr.pid 2>/dev/null) && kill -INT "$pid" && rm -f /tmp/gsr.pid && while kill -0 "$pid" 2>/dev/null; do sleep 0.1; done; ghostty --title=name-clip -e nu ${clipSaveScript}' '';

    # Colors from noctalia Eldritch scheme — changing colorscheme requires updating these. Reference: ~/.config/noctalia/colors.json
    commonSettings = {
      font = "JetBrainsMono Nerd Font 12";
      background = "#212337e6";
      color = "#ebfafa";
      border = "#37f499";
      separator = " ➜ ";
      border_width = 2;
      corner_r = 8;
      padding = 15;
      anchor = "center";
      inhibit_compositor_keyboard_shortcuts = true;
    };

    menus = {
      config =
        commonSettings
        // {
          menu = [
            # Quick launches
            {
              key = "Return";
              desc = "ghostty";
              cmd = terminalCmd;
            }
            {
              key = "space";
              desc = "superfile";
              cmd = fileManagerCmd;
            }
            {
              key = "e";
              desc = "euphonica";
              cmd = euphonicaCmd;
            }
            {
              key = "h";
              desc = "helium";
              cmd = "helium";
            }
            # Category menus
            {
              key = "c";
              desc = "comms";
              submenu = [
                {
                  key = "v";
                  desc = "vesktop";
                  cmd = "vesktop";
                }
                {
                  key = "g";
                  desc = "gajim";
                  cmd = "gajim";
                }
                {
                  key = "f";
                  desc = "facebook";
                  cmd = "helium --app-id=kippjfofjhjlffjecoapiogbkgbpmgej";
                }
              ];
            }
            {
              key = "d";
              desc = "dev";
              submenu = [
                {
                  key = "f";
                  desc = "fresh";
                  cmd = "ghostty --title=fresh -e fresh";
                }
                {
                  key = "g";
                  desc = "ghostty";
                  cmd = terminalCmd;
                }
                {
                  key = "s";
                  desc = "superfile";
                  cmd = fileManagerCmd;
                }
              ];
            }
            {
              key = "g";
              desc = "games";
              submenu = [
                {
                  key = "s";
                  desc = "steam";
                  cmd = "steam";
                }
                {
                  key = "r";
                  desc = "retroarch";
                  cmd = "retroarch";
                }
                {
                  key = "n";
                  desc = "non-steam";
                  submenu = [
                    {
                      key = "o";
                      desc = "openra";
                      submenu = [
                        {
                          key = "d";
                          desc = "Dune 2000";
                          cmd = "openra-d2k";
                        }
                        {
                          key = "r";
                          desc = "Red Alert";
                          cmd = "openra-ra";
                        }
                        {
                          key = "c";
                          desc = "Tiberian Dawn";
                          cmd = "openra-cnc";
                        }
                      ];
                    }
                    {
                      key = "x";
                      desc = "renegade x";
                      cmd = "steam steam://rungameid/14947236508015263744";
                    }
                  ];
                }
              ];
            }
            {
              key = "m";
              desc = "media";
              submenu = [
                {
                  key = "e";
                  desc = "euphonica";
                  cmd = euphonicaCmd;
                }
                {
                  key = "g";
                  desc = "gimp";
                  cmd = "gimp";
                }
                {
                  key = "q";
                  desc = "qview";
                  cmd = "qview";
                }
                {
                  key = "v";
                  desc = "stremio";
                  cmd = "flatpak run com.stremio.Stremio";
                }
                {
                  key = "z";
                  desc = "zathura";
                  cmd = "zathura";
                }
              ];
            }
            {
              key = "t";
              desc = "tools";
              submenu = [
                {
                  key = "b";
                  desc = "btop";
                  cmd = btopCmd;
                }
                {
                  key = "c";
                  desc = "cryptomator";
                  cmd = "cryptomator";
                }
                {
                  key = "f";
                  desc = "filen";
                  cmd = "filen-desktop";
                }
                {
                  key = "g";
                  desc = "ghostty";
                  cmd = terminalCmd;
                }
                {
                  key = "s";
                  desc = "superfile";
                  cmd = fileManagerCmd;
                }
                {
                  key = "l";
                  desc = "lact";
                  cmd = "lact gui";
                }
                {
                  key = "m";
                  desc = "piper";
                  cmd = "piper";
                }
                {
                  key = "n";
                  desc = "nemo";
                  cmd = "nemo";
                }
                {
                  key = "p";
                  desc = "gparted";
                  cmd = "gparted";
                }
                {
                  key = "t";
                  desc = "protontricks";
                  cmd = "protontricks --no-term --gui";
                }
                {
                  key = "u";
                  desc = "protonup-qt";
                  cmd = "protonup-qt";
                }
                {
                  key = "x";
                  desc = "transmission";
                  cmd = "transmission-gtk";
                }
                {
                  key = "v";
                  desc = "virt-manager";
                  cmd = "virt-manager";
                }
              ];
            }
            # Launcher
            {
              key = "question";
              desc = "launcher";
              cmd = "noctalia-shell ipc call launcher toggle";
            }
          ];
        };

      capture =
        commonSettings
        // {
          menu = [
            {
              key = "s";
              desc = "shot";
              submenu = [
                {
                  key = "s";
                  desc = "save";
                  submenu = [
                    {
                      key = "r";
                      desc = "region";
                      cmd = shotRegionSaveCmd;
                    }
                    {
                      key = "w";
                      desc = "window";
                      cmd = shotWindowSaveCmd;
                    }
                    {
                      key = "s";
                      desc = "screen";
                      cmd = shotScreenSaveCmd;
                    }
                  ];
                }
                {
                  key = "c";
                  desc = "clipboard";
                  submenu = [
                    {
                      key = "r";
                      desc = "region";
                      cmd = "hyprshot -m region -z --clipboard-only";
                    }
                    {
                      key = "w";
                      desc = "window";
                      cmd = "hyprshot -m window -z --clipboard-only";
                    }
                    {
                      key = "s";
                      desc = "screen";
                      cmd = "hyprshot -m output -z --clipboard-only";
                    }
                  ];
                }
              ];
            }
            {
              key = "c";
              desc = "clip";
              submenu = [
                {
                  key = "r";
                  desc = "region → record";
                  cmd = clipRegionCmd;
                }
                {
                  key = "w";
                  desc = "window → record";
                  cmd = clipWindowCmd;
                }
                {
                  key = "s";
                  desc = "screen → record";
                  cmd = clipScreenCmd;
                }
                {
                  key = "x";
                  desc = "stop";
                  cmd = stopRecordCmd;
                }
              ];
            }
          ];
        };

      power =
        commonSettings
        // {
          menu = [
            {
              key = "l";
              desc = "lock";
              cmd = "noctalia-shell ipc call lockScreen lock";
            }
            {
              key = "r";
              desc = "reboot";
              cmd = "reboot";
            }
            {
              key = "s";
              desc = "shutdown";
              cmd = "poweroff";
            }
          ];
        };
    };
  in {
    config = lib.mkIf config.mySystem.features.desktop {
      users.users.${username}.packages = [pkgs.wlr-which-key pkgs.libwebp];

      hjem.users.${username}.xdg.config.files = lib.mapAttrs' (name: cfg:
        lib.nameValuePair "wlr-which-key/${name}.yaml" {
          source = yamlFormat.generate "${name}.yaml" cfg;
        })
      menus;
    };
  };
}
