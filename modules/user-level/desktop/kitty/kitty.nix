{
  config,
  pkgs,
  ...
}:
{
  users.users.${config.mySystem.user.name}.packages = [ pkgs.kitty ];

  hjem.users.${config.mySystem.user.name}.xdg.config.files."kitty/kitty.conf" = {
    source = ./kitty.conf;
    # copied at 0644 rather than symlinked because noctalia's kitty template rewrites this file in place
    type = "copy";
    permissions = "0644";
  };

  # noctalia renders themes/noctalia.conf in here at runtime
  preservation.preserveAt."/persist".users.${config.mySystem.user.name}.directories = [
    ".config/kitty"
  ];
}
