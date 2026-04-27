{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.yazi = pkgs.yazi.override {extraPackages = [pkgs.exiftool];};
  };

  flake.nixosModules.yazi = {
    config,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    homeDir = config.users.users.${username}.home;

    yaziPkg = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.yazi;

    wrapperScript = pkgs.writeText "yazi-wrapper.nu" ''
      #!${pkgs.nushell}/bin/nu

      def main [
          multiple: string,
          directory: string,
          save: string,
          path: string,
          out: string,
          debug?: string,
      ] {
          let cwd_file = $"($out).1"

          if $save == "1" or $directory == "1" {
              ghostty --title=termfilechooser -e yazi $"--chooser-file=($out)" $"--cwd-file=($cwd_file)" $path
              let out_empty = not ($out | path exists) or ((ls $out | first | get size) == 0B)
              let cwd_nonempty = ($cwd_file | path exists) and ((ls $cwd_file | first | get size) > 0B)
              if $out_empty and $cwd_nonempty {
                  if $save == "1" {
                      # reconstruct full save path: cwd + suggested filename from app
                      let cwd = open $cwd_file | str trim
                      $"($cwd)/($path | path basename)" | save -f $out
                  } else {
                      open --raw $cwd_file | save -f $out
                  }
              }
              if ($cwd_file | path exists) { ^rm -f $cwd_file }
          } else {
              ghostty --title=termfilechooser -e yazi $"--chooser-file=($out)" $path
          }
      }
    '';
  in {
    users.users.${username}.packages = [yaziPkg];

    hjem.users.${username}.xdg.config.files = {
      "xdg-desktop-portal-termfilechooser/config".text = ''
        [filechooser]
        cmd=${homeDir}/.config/xdg-desktop-portal-termfilechooser/yazi-wrapper.nu
        default_dir=$HOME
        create_help_file=0
        save_mode=last
      '';

      # portal searches lowercase; hyprland pkg ships its own hyprland-portals.conf which wins otherwise
      "xdg-desktop-portal/hyprland-portals.conf".text = ''
        [preferred]
        default=hyprland;gtk
        org.freedesktop.impl.portal.FileChooser=termfilechooser;gtk
        org.freedesktop.impl.portal.ScreenCast=hyprland
        org.freedesktop.impl.portal.Screenshot=hyprland
      '';

      "xdg-desktop-portal-termfilechooser/yazi-wrapper.nu" = {
        source = wrapperScript;
        type = "copy";
        permissions = "0755";
      };
    };
  };
}
