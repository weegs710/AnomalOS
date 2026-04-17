{
  flake.nixosModules.creation = {
    config,
    pkgs,
    ...
  }: {
    programs.gpu-screen-recorder.enable = true;

    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      gimp3-with-plugins
      gpu-screen-recorder
      inkscape
    ];
  };
}
