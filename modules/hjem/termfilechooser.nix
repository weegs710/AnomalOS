{
  flake.nixosModules.termfilechooser = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    homeDir = config.users.users.${username}.home;
    wrapperScript = pkgs.writeText "superfile-wrapper.nu" ''
      #!${pkgs.nushell}/bin/nu

      def main [
          multiple: string,
          directory: string,
          save: string,
          path: string,
          out: string,
          debug?: string,
      ] {
          # superfile exposes no save/directory/multiple protocol; --chooser-file covers all modes
          ghostty --title=termfilechooser -e superfile $"--chooser-file=($out)" $path
      }
    '';
  in {
    config = lib.mkIf config.mySystem.features.desktop {
      hjem.users.${username} = {
        xdg.config.files = {
          "xdg-desktop-portal-termfilechooser/config".text = ''
            [filechooser]
            cmd=${homeDir}/.config/xdg-desktop-portal-termfilechooser/superfile-wrapper.nu
            default_dir=$HOME
            create_help_file=0
          '';

          # portal searches lowercase; hyprland pkg ships its own hyprland-portals.conf which wins otherwise
          "xdg-desktop-portal/hyprland-portals.conf".text = ''
            [preferred]
            default=hyprland;gtk
            org.freedesktop.impl.portal.FileChooser=termfilechooser;gtk
            org.freedesktop.impl.portal.ScreenCast=hyprland
            org.freedesktop.impl.portal.Screenshot=hyprland
          '';

          "xdg-desktop-portal-termfilechooser/superfile-wrapper.nu" = {
            source = wrapperScript;
            type = "copy";
            permissions = "0755";
          };
        };
      };
    };
  };
}
