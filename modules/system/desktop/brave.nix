{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.desktop {
    programs.chromium = {
      enable = true;

      extraOpts = {
        ExtensionInstallForcelist = [
          "nngceckbapebfimnlniiiahkandclblb" # Bitwarden Password Manager
          "neebplgakaahbhdphmkckjjcegoiijjo" # Keepa - Amazon Price Tracker
          "bkcghongfpfngpdobomhdehbffibkjlh" # Windowed Fullscreen for Videos
          # "clngdbkpkpeebahjckkjfobafhncgmne"  # Stylus - CSS injector for web16 theming
        ];
      };
    };

    environment.systemPackages = with pkgs; [
      brave
    ];

    # Native Wayland support for Chromium-based browsers
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    stylix.targets.chromium.enable = false;
  };
}
