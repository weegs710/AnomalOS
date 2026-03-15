{
  flake.nixosModules.desktop-services = {
    config,
    lib,
    ...
  }: {
    config = lib.mkIf config.mySystem.features.desktop {
      services = {
        displayManager = {
          defaultSession = "hyprland";
          ly = {
            enable = true;
          };
        };
        blueman.enable = true;
        upower.enable = true;
        ratbagd.enable = true;
        udisks2.enable = true;
        gvfs.enable = true;
        locate.enable = true;
      };

      programs = {
        partition-manager.enable = true;
      };
    };
  };
}
