{inputs, ...}: {
  flake.nixosModules.helium = {
    config,
    lib,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
    wrappedHelium = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.helium;

    # HeliumLayoutType::kToolbar = 1; sets tabs-in-toolbar layout
    # See: https://github.com/imputnet/helium/blob/main/patches/helium/ui/layout/core.patch
    initialPreferences = builtins.toJSON {
      helium.browser.layout = 1;
    };

    # --hide-crashed-bubble is a switch, not a feature flag
    # See: https://github.com/imputnet/helium/blob/main/patches/ungoogled-chromium/add-flag-to-hide-crashed-bubble.patch
    userFlags = ''
      --hide-crashed-bubble
      --disable-features=EyeDropper
    '';
  in {
    config = lib.mkIf config.mySystem.features.desktop {
      users.users.${username}.packages = [wrappedHelium];

      hjem.users.${username} = {
        xdg.config.files = {
          # Read once on first launch only; will not override an existing profile
          "net.imput.helium/initial_preferences".text = initialPreferences;
          # Read by the shareable wrapper; one flag per line
          "net.imput.helium/user-flags".text = userFlags;
        };
      };
    };
  };
}
