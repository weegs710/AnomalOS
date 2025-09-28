{ config, lib, ... }:

with lib;

{
  imports = [
    ./claude-code.nix
    ./editors.nix
    ./languages.nix
  ];

  config = mkIf config.mySystem.features.development {
    # Enable basic development tools when development module is enabled
    programs = {
      git.enable = true;
      direnv = {
        enable = true;
        silent = true;
        nix-direnv.enable = true;
        direnvrcExtra = ''
          warn_timeout=0
          hide_env_diff=true
        '';
      };
    };
  };
}