# Configuration is handled by Home Manager (modules/nixos-modules/helium.nix)
# This wrapper bundles DRM support and auto-installs extensions
{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    heliumPkg = inputs.helium.defaultPackage.${system};

    extensionPolicy = pkgs.writeText "policy.json" (builtins.toJSON {
      ExtensionInstallForcelist = [
        "nngceckbapebfimnlniiiahkandclblb;https://clients2.google.com/service/update2/crx" # Bitwarden
        "agleiimpggapjekcdhdjbmegjbbkleie;https://clients2.google.com/service/update2/crx" # Ground News
        "odibgflepadohfmpcemnjbhkionjkapk;https://clients2.google.com/service/update2/crx" # Helium Translator Inline
        "neebplgakaahbhdphmkckjjcegoiijjo;https://clients2.google.com/service/update2/crx" # Keepa
        "bkcghongfpfngpdobomhdehbffibkjlh;https://clients2.google.com/service/update2/crx" # Windowed Fullscreen
      ];
    });

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
          --add-flags "--enable-features=WebUIDarkMode,HeliumCatUi,HideCrashedBubble,LinkPreview" \
          --add-flags "--disable-features=EyeDropper,HeliumCatFixedAddressBar" \
          --add-flags "--policy-dir=${policiesDir}/etc/opt/chrome/policies"
      '';
      meta = {
        mainProgram = "helium";
        description = "Helium browser with DRM, dark UI, and bundled extensions";
      };
    };
  in {
    packages.helium = wrappedHelium;
  };
}
