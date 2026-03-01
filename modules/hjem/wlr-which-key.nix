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
          {key = "e"; desc = "endcord"; cmd = "ghostty --title=endcord --font-size=11 -e endcord";}
          {key = "f"; desc = "flow"; cmd = ''ghostty --title=flow -e fish -c "cd ${homeDir}/dotfiles && exec flow"'';}
          {key = "s"; desc = "steam"; cmd = "steam";}
          {key = "m"; desc = "euphonica"; cmd = euphonicaCmd;}
          {key = "v"; desc = "stremio"; cmd = "flatpak run com.stremio.Stremio";}
          {key = "h"; desc = "helium"; cmd = "helium";}
          {key = "b"; desc = "btop"; cmd = btopCmd;}
          {key = "question"; desc = "launcher"; cmd = "noctalia-shell ipc call launcher toggle";}
          {
            key = "Print";
            desc = "screenshot";
            submenu = [
              {key = "r"; desc = "region → clipboard"; cmd = "hyprshot -m region --clipboard-only";}
              {key = "s"; desc = "region → save"; cmd = "hyprshot -m region -o ${homeDir}/Pictures";}
              {key = "w"; desc = "window → clipboard"; cmd = "hyprshot -m window --clipboard-only";}
            ];
          }
          {
            key = "p";
            desc = "power";
            submenu = [
              {key = "l"; desc = "lock"; cmd = "noctalia-shell ipc call lockScreen lock";}
              {key = "s"; desc = "sleep"; cmd = "systemctl suspend";}
              {key = "r"; desc = "reboot"; cmd = "reboot";}
              {key = "q"; desc = "shutdown"; cmd = "poweroff";}
            ];
          }
          {
            key = "c";
            desc = "comms";
            submenu = [
              {key = "e"; desc = "endcord"; cmd = "ghostty --title=endcord --font-size=11 -e endcord";}
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
              {key = "s"; desc = "steam"; cmd = "steam";}
              {key = "r"; desc = "retroarch"; cmd = "retroarch";}
              {
                key = "o";
                desc = "openra";
                submenu = [
                  {key = "r"; desc = "Red Alert"; cmd = "openra-ra";}
                  {key = "c"; desc = "Tiberian Dawn"; cmd = "openra-cnc";}
                  {key = "d"; desc = "Dune 2000"; cmd = "openra-d2k";}
                ];
              }
              {key = "p"; desc = "protonup-qt"; cmd = "protonup-qt";}
            ];
          }
          {
            key = "a";
            desc = "media";
            submenu = [
              {key = "m"; desc = "euphonica"; cmd = euphonicaCmd;}
              {key = "v"; desc = "stremio"; cmd = "flatpak run com.stremio.Stremio";}
              {key = "g"; desc = "gimp"; cmd = "gimp";}
            ];
          }
          {
            key = "t";
            desc = "tools";
            submenu = [
              {key = "b"; desc = "btop"; cmd = btopCmd;}
              {key = "n"; desc = "nemo"; cmd = "nemo";}
              {key = "c"; desc = "cryptomator"; cmd = "cryptomator";}
              {key = "x"; desc = "transmission"; cmd = "transmission-gtk";}
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
