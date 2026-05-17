{
  config,
  pkgs,
  ...
}:
{
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

      min-free = 5368709120; # 5GB (bytes) -- trigger GC before builds fail
      max-free = 16106127360; # 15GB (bytes) -- stop GC once there's real breathing room
    };

    optimise = {
      automatic = true;
      dates = [ "00:00" ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    curl
    git
    nh
    wget
  ];
}
