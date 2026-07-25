{
  config,
  weegsware,
  ...
}:
let
  username = config.mySystem.user.name;
in
{
  users.users.${username}.packages = [ weegsware.helium ];

  # basename is hard-patched to the reverse-DNS id in chrome_paths_linux.cc, not "helium"; whole dir persisted so future subdirs are auto-covered
  # See: https://github.com/imputnet/helium-linux/blob/main/patches/helium/linux/change-chromium-branding.patch
  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/net.imput.helium"
  ];
}
