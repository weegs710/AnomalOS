{...}: {
  flake.nixosModules.tools = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; {
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

        environment.systemPackages = with pkgs; [
          jujutsu
        ];
      };
    };
}
