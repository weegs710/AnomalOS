{ ... }:
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

    k8sLab = {
      manualPrep = true;
      manualPkgs = true;
    };
  };

  # Pure-tack: nh reads NH_FILE instead of NH_FLAKE; NH_ATTRP is derived from the host directory name
  environment.variables = {
    NH_FILE = "/home/weegs/repo/public/anomalos/assemble.nix";
  };

  system.stateVersion = "24.11";
}
