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

  # Essential system packages and scripts
  environment.systemPackages = with pkgs; [
    curl
    git
    wget

    # Custom *-up scripts - portable across users
    (pkgs.writeScriptBin "rig-up" ''
      #!/usr/bin/env bash
      # Update flake, test Rig configuration, and prompt to switch
      set -e
      cd ~/dotfiles/
      echo "Updating flake..."
      nix flake update
      echo "Testing Rig configuration..."
      sudo nixos-rebuild test --flake .#Rig
      if [ $? -eq 0 ]; then
          echo -n "Test successful! Switch to new configuration? [y/N] "
          read -r response
          if [[ "$response" =~ ^[Yy]$ ]]; then
              echo "Switching to new configuration..."
              sudo nixos-rebuild switch --flake .#Rig
              echo "Successfully switched to Rig configuration!"
          else
              echo "Test configuration not applied. You can run 'nrs-rig' later to switch."
          fi
      else
          echo "Test failed! Configuration not applied."
          exit 1
      fi
    '')
    (pkgs.writeScriptBin "hack-up" ''
      #!/usr/bin/env bash
      # Update flake, test Hack configuration, and prompt to switch
      set -e
      cd ~/dotfiles/
      echo "Updating flake..."
      nix flake update
      echo "Testing Hack configuration..."
      sudo nixos-rebuild test --flake .#Hack
      if [ $? -eq 0 ]; then
          echo -n "Test successful! Switch to new configuration? [y/N] "
          read -r response
          if [[ "$response" =~ ^[Yy]$ ]]; then
              echo "Switching to new configuration..."
              sudo nixos-rebuild switch --flake .#Hack
              echo "Successfully switched to Hack configuration!"
          else
              echo "Test configuration not applied. You can run 'nrs-hack' later to switch."
          fi
      else
          echo "Test failed! Configuration not applied."
          exit 1
      fi
    '')
    (pkgs.writeScriptBin "guard-up" ''
      #!/usr/bin/env bash
      # Update flake, test Guard configuration, and prompt to switch
      set -e
      cd ~/dotfiles/
      echo "Updating flake..."
      nix flake update
      echo "Testing Guard configuration..."
      sudo nixos-rebuild test --flake .#Guard
      if [ $? -eq 0 ]; then
          echo -n "Test successful! Switch to new configuration? [y/N] "
          read -r response
          if [[ "$response" =~ ^[Yy]$ ]]; then
              echo "Switching to new configuration..."
              sudo nixos-rebuild switch --flake .#Guard
              echo "Successfully switched to Guard configuration!"
          else
              echo "Test configuration not applied. You can run 'nrs-guard' later to switch."
          fi
      else
          echo "Test failed! Configuration not applied."
          exit 1
      fi
    '')
    (pkgs.writeScriptBin "stub-up" ''
      #!/usr/bin/env bash
      # Update flake, test Stub configuration, and prompt to switch
      set -e
      cd ~/dotfiles/
      echo "Updating flake..."
      nix flake update
      echo "Testing Stub configuration..."
      sudo nixos-rebuild test --flake .#Stub
      if [ $? -eq 0 ]; then
          echo -n "Test successful! Switch to new configuration? [y/N] "
          read -r response
          if [[ "$response" =~ ^[Yy]$ ]]; then
              echo "Switching to new configuration..."
              sudo nixos-rebuild switch --flake .#Stub
              echo "Successfully switched to Stub configuration!"
          else
              echo "Test configuration not applied. You can run 'nrs-stub' later to switch."
          fi
      else
          echo "Test failed! Configuration not applied."
          exit 1
      fi
    '')
  ];

  # Basic shell aliases
  environment.shellAliases = {
    nfa = "cd ~/dotfiles/ && nix flake archive";
    recycle = "sudo nix-collect-garbage --delete-older-than 7d";
    update = "cd ~/dotfiles/ && nix flake update";

    # Configuration-specific rebuild aliases
    nrs-rig = "cd ~/dotfiles/ && sudo nixos-rebuild switch --flake .#Rig";
    nrt-rig = "cd ~/dotfiles/ && sudo nixos-rebuild test --flake .#Rig";
    nrs-hack = "cd ~/dotfiles/ && sudo nixos-rebuild switch --flake .#Hack";
    nrt-hack = "cd ~/dotfiles/ && sudo nixos-rebuild test --flake .#Hack";
    nrs-guard = "cd ~/dotfiles/ && sudo nixos-rebuild switch --flake .#Guard";
    nrt-guard = "cd ~/dotfiles/ && sudo nixos-rebuild test --flake .#Guard";
    nrs-stub = "cd ~/dotfiles/ && sudo nixos-rebuild switch --flake .#Stub";
    nrt-stub = "cd ~/dotfiles/ && sudo nixos-rebuild test --flake .#Stub";
  };

}
