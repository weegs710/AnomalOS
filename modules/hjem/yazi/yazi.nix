{
  config,
  pkgs,
  lib,
  ...
}:
let
  username = config.mySystem.user.name;

  yaziPkg = pkgs.yazi.override { extraPackages = [ pkgs.exiftool ]; };

  wrapperScript = pkgs.writeText "yazi-wrapper.nu" (
    lib.replaceStrings [ "@NUSHELL@" ] [ "${pkgs.nushell}" ] (builtins.readFile ./yazi-wrapper.nu)
  );
in
{
  users.users.${username}.packages = [ yaziPkg ];

  hjem.users.${username}.xdg.config.files = {
    "yazi/yazi.toml".source = ./yazi.toml;
    "yazi/keymap.toml".source = ./keymap.toml;
    "yazi/theme.toml".source = ./theme.toml;
    "yazi/package.toml".source = ./package.toml;

    "xdg-desktop-portal-termfilechooser/config".text = lib.replaceStrings [ "@USER@" ] [ username ] (
      builtins.readFile ./termfilechooser-config
    );

    # portal searches lowercase; hyprland pkg ships its own hyprland-portals.conf which wins otherwise
    "xdg-desktop-portal/hyprland-portals.conf".source = ./hyprland-portals.conf;

    "xdg-desktop-portal-termfilechooser/yazi-wrapper.nu" = {
      source = wrapperScript;
      type = "copy";
      permissions = "0755";
      clobber = false;
    };
  };
}
