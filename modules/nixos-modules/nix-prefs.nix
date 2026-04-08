{
  flake.nixosModules.nix-prefs = {
    config,
    pkgs,
    ...
  }: {
    nix = {
      settings = {
        warn-dirty = false;
        trusted-users = [config.mySystem.user.name];
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        cores = 0;
        max-jobs = "auto";
      };

      optimise = {
        automatic = true;
        dates = ["00:00"];
      };
    };

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      curl
      git
      nh
      wget
    ];
  };
}
