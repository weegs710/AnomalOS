{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
in
{
  users.users.${username}.packages = [ pkgs.zennotes-desktop ];

  # two dirs that differ only by case: .config/ZenNotes is the Electron profile and the remembered vault, .config/zennotes holds the toml settings
  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/ZenNotes"
    ".config/zennotes"
  ];
}
