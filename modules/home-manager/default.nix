# Home-Manager user configuration
# All user-level configuration (desktop environment, applications, dotfiles)
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./core
    ./desktop
    ./development
  ];
}
