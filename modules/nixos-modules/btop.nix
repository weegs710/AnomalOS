{
  flake.nixosModules.btop = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.mySystem.features.desktop {
        users.users.${config.mySystem.user.name}.packages = with pkgs; [
          btop-rocm
        ];
      };
    };
}
