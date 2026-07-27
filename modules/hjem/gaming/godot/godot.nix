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
    pkgs.godot_4
    pkgs.gdtoolkit_4
    pkgs.pixelorama
    pkgs.tiled
    pkgs.sfxr-qt
    pkgs.audacity
  ];

  # symlink the whole dir so godot finds templates by version-subdir and re-points itself on every godot bump, no hardcoded version
  # See: https://wiki.nixos.org/wiki/Godot
  hjem.users.${username}.xdg.data.files."godot/export_templates".source =
    "${pkgs.godot_4.export-templates-bin}/share/godot/export_templates";

  systemd.user.tmpfiles.rules = [
    "d %h/.local/share/godot/projects 0755 - - -"
  ];

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/godot"
    ".local/share/godot"
  ];
}
