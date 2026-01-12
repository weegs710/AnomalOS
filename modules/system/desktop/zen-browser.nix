{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.desktop {
    environment.systemPackages = [
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
