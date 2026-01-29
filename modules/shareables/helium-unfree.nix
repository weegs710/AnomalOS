# Wrapped helium browser with Widevine DRM, dark mode, and extension policies
# Run with: NIXPKGS_ALLOW_UNFREE=1 nix run --impure github:weegs710/AnomalOS#helium-unfree
{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    heliumPkg = inputs.helium.defaultPackage.${system};

    # Widevine CDM config for DRM streaming (Netflix, Disney+, etc.)
    widevineCdmConfig = pkgs.writeText "latest-component-updated-widevine-cdm" ''
      {"Path":"${pkgs.widevine-cdm}/share/google/chrome/WidevineCdm"}
    '';

    # Policy to auto-install extensions from Chrome Web Store
    extensionPolicy = pkgs.writeText "policy.json" (builtins.toJSON {
      ExtensionInstallForcelist = [
        "agleiimpggapjekcdhdjbmegjbbkleie;https://clients2.google.com/service/update2/crx" # Ground News
        "bkcghongfpfngpdobomhdehbffibkjlh;https://clients2.google.com/service/update2/crx" # Windowed Fullscreen
        "neebplgakaahbhdphmkckjjcegoiijjo;https://clients2.google.com/service/update2/crx" # Keepa
        "nngceckbapebfimnlniiiahkandclblb;https://clients2.google.com/service/update2/crx" # Bitwarden
      ];
    });

    # Create a policies directory structure
    policiesDir = pkgs.runCommand "helium-policies" {} ''
      mkdir -p $out/etc/opt/chrome/policies/managed
      cp ${extensionPolicy} $out/etc/opt/chrome/policies/managed/extensions.json
    '';

    wrappedHelium = pkgs.symlinkJoin {
      name = "helium-wrapped";
      paths = [heliumPkg];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/helium \
          --add-flags "--enable-features=WebUIDarkMode,ForceDarkMode" \
          --add-flags "--force-dark-mode" \
          --add-flags "--policy-dir=${policiesDir}/etc/opt/chrome/policies" \
          --run "mkdir -p ~/.config/net.imput.helium/WidevineCdm && cp -n ${widevineCdmConfig} ~/.config/net.imput.helium/WidevineCdm/latest-component-updated-widevine-cdm 2>/dev/null || true"
      '';
      meta.mainProgram = "helium";
    };
  in {
    packages.helium-unfree = wrappedHelium;
  };
}
