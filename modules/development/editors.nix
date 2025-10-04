{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  config = mkIf config.mySystem.features.development {
    # Add development editors to user packages
    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      zed-editor
    ];

    # Development programs
    programs = {
      tmux.enable = true;
      starship.enable = true;
    };
  };
}
