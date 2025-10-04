{
  config,
  lib,
  pkgs,
  ...
}:

{
  users = {
    defaultUserShell = pkgs.fish;

    users.${config.mySystem.user.name} = {
      isNormalUser = true;
      description = config.mySystem.user.description;
      extraGroups = config.mySystem.user.extraGroups;
      packages = with pkgs; [
        # Basic user packages - specific features add their own
      ];
    };
  };

  # Basic shell setup
  programs.fish.enable = true;
}
