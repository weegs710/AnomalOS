{ config, ... }:
let
  username = config.mySystem.user.name;
in
{
  # copy-type and writable: peepers saves its settings in place, which a read-only store link would refuse; gui edits get pulled back with `peep-s`
  hjem.users.${username}.xdg.config.files."peepers/settings.toml" = {
    source = ./settings.toml;
    type = "copy";
    clobber = false;
    permissions = "0644";
  };
}
