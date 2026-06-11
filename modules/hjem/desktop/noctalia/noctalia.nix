{
  config,
  ...
}:
let
  username = config.mySystem.user.name;
in
{
  environment.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };

  # noctalia writes runtime state + git-cloned plugin/palette caches here; persist it so the tmpfs root reboot doesn't re-clone every boot
  preservation.preserveAt."/persist".users.${username}.directories = [
    ".local/state/noctalia"
  ];

  hjem.users.${username} = {
    # qt6ct ships no config; without an icon theme Qt resolves named icons to the missing-icon checker
    xdg.config.files."qt6ct/qt6ct.conf".text = ''
      [Appearance]
      icon_theme=Adwaita
    '';
  };
}
