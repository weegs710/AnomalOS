{
  config,
  lib,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
  homeDir = config.users.users.${username}.home;
  yamlFormat = pkgs.formats.yaml { };

  jellyfinCmd = "hyprctl dispatch \"hl.dsp.exec_cmd('env MOZ_APP_LAUNCHER=zen-jellyfin zen --kiosk --profile ${homeDir}/.local/share/zen-jellyfin --no-remote http://localhost:8096', { workspace = '5' })\"";
  concordCmd = "hyprctl dispatch \"hl.dsp.exec_cmd('ghostty --title=concord -e /etc/profiles/per-user/${username}/bin/concord')\"";
  weechatCmd = "hyprctl dispatch \"hl.dsp.exec_cmd('ghostty --title=weechat -e weechat')\"";
  gorguruCmd = "hyprctl dispatch \"hl.dsp.exec_cmd('ghostty --title=gorguru -e ${homeDir}/repo/private/weegs.dev/dist/gorguru', { workspace = 'special:stash' })\"";
  btopCmd = "hyprctl dispatch \"hl.dsp.exec_cmd('ghostty --title=btop -e btop', { float = true, size = {1600, 900}, move = {531, 262} })\"";
  rmpcCmd = "hyprctl dispatch \"hl.dsp.exec_cmd('ghostty --title=rmpc -e rmpc')\"";
  terminalCmd = "ghostty --title=ghostty";
  fileManagerCmd = "hyprctl dispatch \"hl.dsp.exec_cmd('ghostty -e yazi', { float = true, size = {1600, 900}, move = {531, 262} })\"";

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

  shotRegionClipCmd = "nu -c 'sleep 500ms; ^hyprshot -m region -z --clipboard-only'";
  shotWindowClipCmd = "nu -c 'sleep 500ms; ^hyprshot -m window -z --clipboard-only'";
  shotScreenClipCmd = "nu -c 'sleep 500ms; ^hyprshot -m output -z --clipboard-only'";
  shotRegionSaveCmd = ''nu -c 'sleep 500ms; let fn = $"/tmp/wkshot_(random int).png"; ^hyprshot -m region -z --raw | save --raw $fn; ^ghostty --title=name-shot -e nu ${shotSaveScript} $fn' '';
  shotWindowSaveCmd = ''nu -c 'sleep 500ms; let fn = $"/tmp/wkshot_(random int).png"; ^hyprshot -m window -z --raw | save --raw $fn; ^ghostty --title=name-shot -e nu ${shotSaveScript} $fn' '';
  shotScreenSaveCmd = ''nu -c 'sleep 500ms; let fn = $"/tmp/wkshot_(random int).png"; ^hyprshot -m output -z --raw | save --raw $fn; ^ghostty --title=name-shot -e nu ${shotSaveScript} $fn' '';
  clipScreenCmd = "nu ${clipStartScript} screen";
  stopRecordCmd = ''nu -c 'if ("/tmp/gsr.pid" | path exists) { let pid = (open /tmp/gsr.pid | str trim | into int); ^kill -INT $pid; ^rm /tmp/gsr.pid; while (ps | where pid == $pid | is-not-empty) { sleep 100ms } }; ^wlr-which-key ~/.config/wlr-which-key/post-record.yaml' '';

  # noctalia colorscheme change requires updating these hex values -- See: ~/.config/noctalia/colors.json
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
    config = commonSettings // {
      menu = [
        # Quick launches
        {
          key = "Return";
          desc = "ghostty";
          cmd = terminalCmd;
        }
        {
          key = "r";
          desc = "rmpc";
          cmd = rmpcCmd;
        }
        {
          key = "e";
          desc = "weegsmacs";
          cmd = "emacs";
        }
        {
          key = "z";
          desc = "zen";
          cmd = "zen";
        }
        {
          key = "j";
          desc = "jellyfin";
          cmd = jellyfinCmd;
        }
        # Category menus
        {
          key = "c";
          desc = "comms";
          submenu = [
            {
              key = "c";
              desc = "concord";
              cmd = concordCmd;
            }
            {
              key = "w";
              desc = "weechat";
              cmd = weechatCmd;
            }
            {
              key = "f";
              desc = "facebook";
              cmd = "hyprctl dispatch \"hl.dsp.exec_cmd('zen --no-remote --new-window https://www.facebook.com', { workspace = 1 })\"";
            }
          ];
        }
        {
          key = "d";
          desc = "dev";
          submenu = [
            {
              key = "g";
              desc = "ghostty";
              cmd = terminalCmd;
            }
            {
              key = "y";
              desc = "yazi";
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
              key = "h";
              desc = "heroic";
              cmd = "heroic";
            }
            {
              key = "g";
              desc = "gorguru";
              cmd = gorguruCmd;
            }
            {
              key = "c";
              desc = "Dungeon Crawl Stone Soup";
              cmd = "crawl-tiles";
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
              key = "r";
              desc = "rmpc";
              cmd = rmpcCmd;
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
              key = "g";
              desc = "ghostty";
              cmd = terminalCmd;
            }
            {
              key = "y";
              desc = "yazi";
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
              cmd = "tremc";
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
          key = "space";
          desc = "launcher";
          cmd = "noctalia-shell ipc call launcher toggle";
        }
      ];
    };

    capture = commonSettings // {
      menu = [
        {
          key = "x";
          desc = "stop recording";
          cmd = stopRecordCmd;
        }
        {
          key = "r";
          desc = "region → clipboard";
          cmd = shotRegionClipCmd;
        }
        {
          key = "w";
          desc = "window → clipboard";
          cmd = shotWindowClipCmd;
        }
        {
          key = "s";
          desc = "screen → clipboard";
          cmd = shotScreenClipCmd;
        }
        {
          key = "f";
          desc = "save to file";
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
          desc = "start recording";
          cmd = clipScreenCmd;
        }
      ];
    };

    "post-record" = commonSettings // {
      menu = [
        {
          key = "s";
          desc = "save clip";
          cmd = "ghostty --title=name-clip -e nu ${clipSaveScript}";
        }
        {
          key = "d";
          desc = "discard";
          cmd = "rm -f /tmp/gsr_clip.mp4";
        }
      ];
    };

    power = commonSettings // {
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
in
{
  users.users.${username}.packages = [
    pkgs.wlr-which-key
    pkgs.libwebp
  ];

  hjem.users.${username}.xdg.config.files = lib.mapAttrs' (
    name: cfg:
    lib.nameValuePair "wlr-which-key/${name}.yaml" {
      source = yamlFormat.generate "${name}.yaml" cfg;
    }
  ) menus;
}
