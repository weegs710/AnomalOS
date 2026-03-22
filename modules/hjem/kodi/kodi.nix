{...}: {
  flake.nixosModules.kodi = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
  in {
    config = lib.mkIf config.mySystem.features.desktop {
      users.users.${username}.packages = [pkgs.kodi];

      hjem.users.${username}.files = {
        ".kodi/userdata/guisettings.xml" = {
          source = ./guisettings.xml;
          type = "copy";
          permissions = "0644";
        };
        ".kodi/userdata/sources.xml" = {
          source = ./sources.xml;
          type = "copy";
          permissions = "0644";
        };
      };
    };
  };
}
