{
  flake.nixosModules.tmux = {
    config,
    lib,
    ...
  }: {
    config = lib.mkIf config.mySystem.features.development {
      programs.tmux.enable = true;
    };
  };
}
