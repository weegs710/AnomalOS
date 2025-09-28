{
  config,
  lib,
  pkgs,
  ...
}:

{
  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 90d";
    };

    settings = {
      auto-optimise-store = true;
      warn-dirty = false;
      download-buffer-size = 268435456; # 256MB
      trusted-users = [ config.mySystem.user.name ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  # Essential system packages
  environment.systemPackages = with pkgs; [
    curl
    git
    wget
  ];

  # Basic shell aliases
  environment.shellAliases = {
    nfa = "cd ~/dotfiles/ && nix flake archive";
    nrs = "cd ~/dotfiles/ && sudo nixos-rebuild switch --flake .#${config.networking.hostName}";
    nrt = "cd ~/dotfiles/ && sudo nixos-rebuild test --flake .#${config.networking.hostName}";
    recycle = "sudo nix-collect-garbage --delete-older-than 7d";
    update-all = "cd ~/dotfiles/ && sudo nix flake update && nrs";
    update-all-test = "cd ~/dotfiles/ && sudo nix flake update && nrt";
  };
}
