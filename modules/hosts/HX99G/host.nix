{ pkgs, ... }:
{
  mySystem = {
    user = {
      name = "weegs";
      description = "weegs";
      extraGroups = [
        "networkmanager"
        "wheel"
        "wireshark"
      ];
    };

    display = {
      width = 2560;
      height = 1440;
      refresh = 144;
    };

    paths.games = "/mnt/games";

    audio.monitorSource = "alsa_output.usb-Jieli_Technology_Tylubio_ST200-00.analog-stereo.monitor";

    btopPackage = pkgs.btop-rocm;

    k8sLab = {
      manualPrep = true;
      manualPkgs = true;
    };

    win11Vm = {
      isoPath = "/var/lib/libvirt/images/Win11.iso";
      resolution = {
        x = 2560;
        y = 1440;
      };
      kiosk.enable = true;
    };
  };

  # Pure-tack: nh reads NH_FILE instead of NH_FLAKE; NH_ATTRP is derived from the host directory name
  environment.variables = {
    NH_FILE = "/home/weegs/repo/public/anomalos/assemble.nix";
  };

  system.stateVersion = "24.11";
}
