{inputs, ...}: {
  flake.nixosModules.helium = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    wrappedHelium = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.helium;
  in
    with lib; {
      config = mkIf config.mySystem.features.desktop {
        users.users.${username}.packages = [ wrappedHelium ];

        hjem.users.${username} = {
          xdg.config.files."net.imput.helium/WidevineCdm/latest-component-updated-widevine-cdm".text = ''
            {"Path":"${pkgs.widevine-cdm}/share/google/chrome/WidevineCdm"}
          '';
        };
      };
    };
}
