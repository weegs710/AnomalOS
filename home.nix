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
    ./modules/system/claude-code-enhanced
    ./modules/home-manager
  ];

  programs.claude-code-enhanced.enable = true;

  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "25.05";

  programs = {
    home-manager.enable = true;
  };

  home.file."claude-projects/.keep" = lib.mkIf osConfig.mySystem.features.claudeCode {
    text = "";
  };

  home.file.".local/share/min-ed-launcher/MinEdLauncher" = {
    source = "${pkgs.min-ed-launcher}/bin/MinEdLauncher";
  };
}
