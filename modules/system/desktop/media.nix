{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.desktop {
    # Hardware support
    hardware = {
      amdgpu.opencl.enable = mkIf config.mySystem.hardware.amd true;
      amdgpu.overdrive.enable = mkIf config.mySystem.hardware.amd true;
      graphics = mkIf config.mySystem.hardware.amd {
        enable = true;
        enable32Bit = true;
      };
      bluetooth.enable = mkIf config.mySystem.hardware.bluetooth true;
    };

    services.lact = mkIf config.mySystem.hardware.amd {
      enable = true;
    };

    programs.gpu-screen-recorder.enable = true;

    # Media applications
    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      gimp3-with-plugins
      gpu-screen-recorder
      video2x
    ];

    # AppImage support
    programs.appimage = {
      enable = true;
      binfmt = true;
    };
  };
}
