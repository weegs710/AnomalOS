{inputs, ...}: {
  flake.nixosModules.helium = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; {
      config = mkIf config.mySystem.features.desktop {
        home-manager.users.${config.mySystem.user.name} = {
          home.packages = [
            inputs.helium.defaultPackage.${pkgs.stdenv.hostPlatform.system}
          ];

          # Widevine CDM configuration for DRM streaming support
          xdg.configFile."net.imput.helium/WidevineCdm/latest-component-updated-widevine-cdm".text = ''
            {"Path":"${pkgs.widevine-cdm}/share/google/chrome/WidevineCdm"}
          '';
        };
      };
    };
}
