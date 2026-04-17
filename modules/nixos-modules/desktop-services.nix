{
  flake.nixosModules.desktop-services = {...}: {
    hardware.bluetooth.enable = true;

    services = {
      blueman.enable = true;
      upower.enable = true;
      ratbagd.enable = true;
      udisks2.enable = true;
      gvfs.enable = true;
      locate.enable = true;
      speechd.enable = false;
    };

    programs = {
      partition-manager.enable = true;
    };
  };
}
