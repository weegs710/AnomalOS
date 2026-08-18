{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.nix-index-database.nixosModules.default ];

  nix = {
    settings = {
      warn-dirty = false;
      trusted-users = [ config.mySystem.user.name ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      cores = 0;
      max-jobs = "auto";

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

      min-free = 5368709120; # 5GB (bytes) -- trigger GC before builds fail
      max-free = 16106127360; # 15GB (bytes) -- stop GC once there's real breathing room
    };

    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 90d";
    };

    optimise = {
      automatic = true;
      dates = [ "00:00" ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  programs.nix-index-database.comma.enable = false;

  environment.systemPackages = with pkgs; [
    curl
    git
    nh
    wget
    inputs.tack.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
