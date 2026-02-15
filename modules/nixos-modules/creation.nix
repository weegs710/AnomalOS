{
  flake.nixosModules.creation = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.mySystem.features.desktop {
        hardware = {
          amdgpu.opencl.enable = lib.mkIf config.mySystem.hardware.amd true;
          amdgpu.overdrive.enable = lib.mkIf config.mySystem.hardware.amd true;
          graphics = lib.mkIf config.mySystem.hardware.amd {
            enable = true;
            enable32Bit = true;
          };
          bluetooth.enable = lib.mkIf config.mySystem.hardware.bluetooth true;
        };

        services.lact = lib.mkIf config.mySystem.hardware.amd {
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
