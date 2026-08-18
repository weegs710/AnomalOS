{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
in
{
  users.users.${username}.packages = [
    pkgs.vesktop
  ];

  # copy-type + writable (vesktop truncate-writes settings via writeFileSync; the store copy is 444 which would EACCES); gui edits get pulled back with `vesk-s`
  hjem.users.${username}.xdg.config.files = {
    "vesktop/settings.json" = {
      source = ./settings.json;
      type = "copy";
      clobber = false;
      permissions = "0644";
    };
    "vesktop/settings/settings.json" = {
      source = ./vencord-settings.json;
      type = "copy";
      clobber = false;
      permissions = "0644";
    };
  };

  # sessionData/ holds the discord login; state.json + themes are runtime-written -- persist so login survives the tmpfs reboot
  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/vesktop"
  ];
}
