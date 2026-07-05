{ ... }:
{
  mySystem = {
    hostName = "HX99G";
    user = {
      name = "weegs";
      description = "weegs";
      extraGroups = [
        "networkmanager"
        "wheel"
        "wireshark"
      ];
    };
  };

  # Pure-tack: nh reads NH_FILE + NH_ATTRP instead of NH_FLAKE
  environment.variables = {
    NH_FILE = "/home/weegs/repo/public/anomalos/assemble.nix";
    NH_ATTRP = "HX99G";
  };

  nix.settings = {
    substituters = [
      "https://anomalos.cachix.org"
      "https://noctalia.cachix.org"
      "https://attic.xuyh0120.win/lantian"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "anomalos.cachix.org-1:Rw01Lh1cj/LULRaPi6S145g1qrRzMr0hxvMTvQE0+Ms="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  system.stateVersion = "24.11";
}
