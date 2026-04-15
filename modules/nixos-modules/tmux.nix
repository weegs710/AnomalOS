{
  flake.nixosModules.tmux = {...}: {
    programs.tmux.enable = true;
  };
}
