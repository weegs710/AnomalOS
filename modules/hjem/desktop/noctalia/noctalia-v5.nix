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

  hjem.users.${username} = {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
    };

    # settings left empty so config.toml stays a standalone first-class file (copied, not nix-generated); v5 hot-reloads it via inotify
    xdg.config.files."noctalia/config.toml" = {
      source = ./config.toml;
      type = "copy";
    };
  };
}
