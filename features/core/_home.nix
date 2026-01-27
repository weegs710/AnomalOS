{
  lib,
  pkgs,
  osConfig,
  inputs,
  ...
}: let
  username = osConfig.mySystem.user.name;
  homeDirectory = "/home/${username}";
in {
  imports = [
    ../development/_claude-code-enhanced
  ];

  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "25.05";

  programs = {
    home-manager.enable = true;
    claude-code-enhanced.enable = true;
  };
}
