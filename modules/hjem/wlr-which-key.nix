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
    euphonicaCmd = "hyprctl dispatch exec '[size 1600 900; move 531 262; float; opacity 1.0 override 1.0 override 1.0 override] euphonica'";

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
      config = commonSettings // {
        menu = [
          # Quick launches
          {key = "b"; desc = "btop"; cmd = btopCmd;}
          {key = "m"; desc = "euphonica"; cmd = euphonicaCmd;}
          {key = "h"; desc = "helium"; cmd = "helium";}
          {key = "s"; desc = "steam"; cmd = "steam";}
          {key = "v"; desc = "stremio"; cmd = "flatpak run com.stremio.Stremio";}
          {key = "z"; desc = "zed"; cmd = "zeditor";}
          # Category menus
          {
            key = "c";
            desc = "comms";
            submenu = [
              {key = "e"; desc = "endcord"; cmd = "ghostty --title=endcord --font-size=11 -e endcord";}
              {key = "g"; desc = "gajim"; cmd = "gajim";}
            ];
          }
          {
            key = "d";
            desc = "dev";
            submenu = [
              {key = "f"; desc = "flow"; cmd = ''ghostty --title=flow -e fish -c "cd ${homeDir}/dotfiles && exec flow"'';}
              {key = "z"; desc = "zed"; cmd = "zeditor";}
            ];
          }
          {
            key = "g";
            desc = "games";
            submenu = [
              {
                key = "o";
                desc = "openra";
                submenu = [
                  {key = "d"; desc = "Dune 2000"; cmd = "openra-d2k";}
                  {key = "r"; desc = "Red Alert"; cmd = "openra-ra";}
                  {key = "c"; desc = "Tiberian Dawn"; cmd = "openra-cnc";}
                ];
              }
              {key = "r"; desc = "retroarch"; cmd = "retroarch";}
              {key = "s"; desc = "steam"; cmd = "steam";}
            ];
          }
          {
            key = "a";
            desc = "media";
            submenu = [
              {key = "m"; desc = "euphonica"; cmd = euphonicaCmd;}
              {key = "g"; desc = "gimp"; cmd = "gimp";}
              {key = "q"; desc = "qview"; cmd = "qview";}
              {key = "v"; desc = "stremio"; cmd = "flatpak run com.stremio.Stremio";}
              {key = "z"; desc = "zathura"; cmd = "zathura";}
            ];
          }
          {
            key = "t";
            desc = "tools";
            submenu = [
              {key = "b"; desc = "btop"; cmd = btopCmd;}
              {key = "c"; desc = "cryptomator"; cmd = "cryptomator";}
              {key = "f"; desc = "filen"; cmd = "filen-desktop";}
              {key = "g"; desc = "gparted"; cmd = "gparted";}
              {key = "l"; desc = "lact"; cmd = "lact gui";}
              {key = "n"; desc = "nemo"; cmd = "nemo";}
              {key = "p"; desc = "piper"; cmd = "piper";}
              {key = "t"; desc = "protontricks"; cmd = "protontricks --no-term --gui";}
              {key = "u"; desc = "protonup-qt"; cmd = "protonup-qt";}
              {key = "x"; desc = "transmission"; cmd = "transmission-gtk";}
              {key = "v"; desc = "virt-manager"; cmd = "virt-manager";}
            ];
          }
          # Launcher
          {key = "question"; desc = "launcher"; cmd = "noctalia-shell ipc call launcher toggle";}
          # Screenshot
          {
            key = "Print";
            desc = "screenshot";
            submenu = [
              {key = "r"; desc = "region → clipboard"; cmd = "hyprshot -m region --clipboard-only";}
              {key = "s"; desc = "region → save"; cmd = "hyprshot -m region -o ${homeDir}/Pictures";}
              {key = "w"; desc = "window → clipboard"; cmd = "hyprshot -m window --clipboard-only";}
            ];
          }
          # Power
          {
            key = "p";
            desc = "power";
            submenu = [
              {key = "l"; desc = "lock"; cmd = "noctalia-shell ipc call lockScreen lock";}
              {key = "r"; desc = "reboot"; cmd = "reboot";}
              {key = "q"; desc = "shutdown"; cmd = "poweroff";}
              {key = "s"; desc = "sleep"; cmd = "systemctl suspend";}
            ];
          }
        ];
      };
    };
  in {
    config = lib.mkIf config.mySystem.features.desktop {
      users.users.${username}.packages = [pkgs.wlr-which-key];

      hjem.users.${username}.xdg.config.files = lib.mapAttrs' (name: cfg:
        lib.nameValuePair "wlr-which-key/${name}.yaml" {
          source = yamlFormat.generate "${name}.yaml" cfg;
        })
      menus;
    };
  };
}
