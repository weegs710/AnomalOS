{
  flake.nixosModules.tools = {
    config,
    lib,
    pkgs,
    ...
  }: {
      config = lib.mkIf config.mySystem.features.development {
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

        users.users.${config.mySystem.user.name}.packages = with pkgs; [
          alejandra
          gh
          hyperfine
          hyprls
          jq
          nodejs
          python3
          ripgrep
          cargo
          rustc
          uv
        ];

        environment.systemPackages = with pkgs; [
          jujutsu
        ];
      };
    };
}
