{
  flake.nixosModules.creation = {
    config,
    pkgs,
    ...
  }: {
    hardware = {
      amdgpu.opencl.enable = true;
      amdgpu.overdrive.enable = true;
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      bluetooth.enable = true;
    };

    services.lact = {
      enable = true;
    };

    programs.gpu-screen-recorder.enable = true;

    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      gimp3-with-plugins
      gpu-screen-recorder
      inkscape
    ];

    programs.appimage = {
      enable = true;
      binfmt = true;
    };
  };
}
