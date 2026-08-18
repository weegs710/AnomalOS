{
  config,
  inputs,
  ...
}:
let
  username = config.mySystem.user.name;
in
{
  hjem.extraModules = [ inputs.noctalia.hjemModules.default ];

  environment.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };

  # noctalia writes runtime state + git-cloned plugin/palette caches here; persist it so the tmpfs root reboot doesn't re-clone every boot
  preservation.preserveAt."/persist".users.${username}.directories = [
    ".local/state/noctalia"
  ];

  hjem.users.${username} = {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
    };

    # settings left empty so config.toml stays a standalone first-class file (copied, not nix-generated); v5 hot-reloads it via inotify
    xdg.config.files."noctalia/config.toml" = {
      source = ./config.toml;
      type = "copy";
      clobber = false;
    };

    # qt6ct ships no config; without an icon theme Qt resolves named icons to the missing-icon checker
    xdg.config.files."qt6ct/qt6ct.conf".source = ./qt6ct.conf;

    xdg.config.files."noctalia/palettes/Twilight.json".source = ./palettes/Twilight.json;
    xdg.config.files."noctalia/palettes/Plasm.json".source = ./palettes/Plasm.json;
    xdg.config.files."noctalia/palettes/Great-Below.json".source = ./palettes/Great-Below.json;
    xdg.config.files."noctalia/palettes/Cold-Wind.json".source = ./palettes/Cold-Wind.json;
  };
}
