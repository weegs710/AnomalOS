{inputs, ...}: {
  flake.nixosModules.flow-control = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    wrappedFlow = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.flow-control;
    customConfigFile = ./custom_config;
  in
    with lib; {
      config = mkIf config.mySystem.features.development {
        users.users.${username}.packages = [wrappedFlow];

        hjem.users.${username} = {
          xdg.config.files."flow/custom_config".source = customConfigFile;
        };
      };
    };
}
