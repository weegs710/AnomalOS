{ config, lib, pkgs, ... }:

with lib;

{
  config = mkIf config.mySystem.features.desktop {
    # Hardware support
    hardware = {
      amdgpu.opencl.enable = mkIf config.mySystem.hardware.amd true;
      graphics = mkIf config.mySystem.hardware.amd {
        enable = true;
        enable32Bit = true;
      };
      bluetooth.enable = mkIf config.mySystem.hardware.bluetooth true;
    };

    # Media applications
    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      obs-studio
      gimp3-with-plugins
    ];

    # AppImage support
    programs.appimage = {
      enable = true;
      binfmt = true;
    };
  };
}