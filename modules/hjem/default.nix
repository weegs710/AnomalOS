{inputs, ...}: {
  flake.nixosModules.hjem = {
    config,
    ...
  }: {
    imports = [
      inputs.hjem.nixosModules.default
    ];

    # Disable Hjem's systemd unit management so Home Manager can manage
    # ~/.config/systemd/user/ for modules not yet migrated
    hjem.users.${config.mySystem.user.name}.systemd.enable = false;
  };
}
