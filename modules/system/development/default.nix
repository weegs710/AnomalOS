{
  config,
  lib,
  ...
}:
with lib; {
  imports = [
    ./android-webcam.nix
    ./claude-code.nix
    ./editors.nix
    ./languages.nix
    ./media.nix
    ./vm.nix
  ];

  config = mkIf config.mySystem.features.development {
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
