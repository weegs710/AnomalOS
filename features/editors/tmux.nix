{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.development {
    programs.tmux.enable = true;
  };
}
