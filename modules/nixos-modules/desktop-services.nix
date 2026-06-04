{ ... }:
{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings.General.Experimental = true;

  services = {
    blueman.enable = true;
    upower.enable = true;
    ratbagd.enable = true;
    udisks2.enable = true;
    gvfs.enable = true;
    locate.enable = true;
    speechd.enable = false; # pulled in as a gnome dependency, not needed
  };

  programs = {
    partition-manager.enable = true;
  };
}
