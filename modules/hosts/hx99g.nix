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
      "https://cache.lix.systems"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "anomalos.cachix.org-1:Rw01Lh1cj/LULRaPi6S145g1qrRzMr0hxvMTvQE0+Ms="
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  system.stateVersion = "24.11";
}
