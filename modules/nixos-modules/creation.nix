{...}: {
  flake.nixosModules.creation = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; {
      config = mkIf config.mySystem.features.desktop {
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

        users.users.${config.mySystem.user.name}.packages = with pkgs; [
          gimp3-with-plugins
          gpu-screen-recorder
          video2x
        ];

        programs.appimage = {
          enable = true;
          binfmt = true;
        };
      };
    };
}
