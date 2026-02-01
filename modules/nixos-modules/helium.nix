{inputs, ...}: {
  flake.nixosModules.helium = {
    config,
    lib,
    pkgs,
    ...
  }: let
    wrappedHelium = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.helium;
  in
    with lib; {
      config = mkIf config.mySystem.features.desktop {
        home-manager.users.${config.mySystem.user.name} = {
          home.packages = [
            wrappedHelium
          ];

          xdg.configFile."net.imput.helium/WidevineCdm/latest-component-updated-widevine-cdm".text = ''
            {"Path":"${pkgs.widevine-cdm}/share/google/chrome/WidevineCdm"}
          '';
        };
      };
    };
}
