{...}: {
  flake.nixosModules.pulsemixer = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; {
      config = mkIf config.mySystem.features.desktop {
        users.users.${config.mySystem.user.name}.packages = with pkgs; [
          pulsemixer
        ];
      };
    };
}
