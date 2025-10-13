{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
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
      trusted-users = [config.mySystem.user.name];
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Build performance
      cores = 0; # 0 = use all available cores
      max-jobs = "auto"; # Let Nix decide based on available resources

      substituters = [
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
        "https://cuda-maintainers.cachix.org" # Includes ROCm packages
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  # Essential system packages and scripts
  environment.systemPackages = with pkgs; [
    curl
    git
    wget
    inputs.helium.defaultPackage.${pkgs.system}

    # Custom *-up scripts - portable across users
    (pkgs.writeScriptBin "rig-up" ''
      #!/usr/bin/env bash
      # Update flake, test Rig configuration, and prompt to switch

      # Colors for output
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      BLUE='\033[0;34m'
      NC='\033[0m' # No Color

      # Error handling
      set -e
      trap 'echo -e "''${RED}Error occurred at line $LINENO. Exiting.''${NC}" >&2' ERR

      # Verify we're in the right directory
      if [ ! -f ~/dotfiles/flake.nix ]; then
          echo -e "''${RED}Error: ~/dotfiles/flake.nix not found''${NC}"
          exit 1
      fi

      cd ~/dotfiles/

      # Update flake
      echo -e "''${BLUE}[1/3] Updating flake inputs...''${NC}"
      if nix flake update; then
          echo -e "''${GREEN}✓ Flake updated successfully''${NC}"
      else
          echo -e "''${RED}✗ Flake update failed''${NC}"
          exit 1
      fi

      # Test configuration
      echo -e "\n''${BLUE}[2/3] Testing Rig configuration...''${NC}"
      if sudo nixos-rebuild test --flake .#Rig; then
          echo -e "''${GREEN}✓ Test completed successfully''${NC}"
      else
          echo -e "''${RED}✗ Test failed! Configuration not applied.''${NC}"
          echo -e "''${YELLOW}Tip: Check the error messages above for details''${NC}"
          exit 1
      fi

      # Prompt to switch
      echo -e "\n''${BLUE}[3/3] Apply configuration?''${NC}"
      echo -e "''${YELLOW}Test successful! Switch to new configuration? [y/N]''${NC} "
      read -r response

      if [[ "$response" =~ ^[Yy]$ ]]; then
          echo -e "''${BLUE}Switching to new configuration...''${NC}"
          if sudo nixos-rebuild switch --flake .#Rig; then
              echo -e "''${GREEN}✓ Successfully switched to Rig configuration!''${NC}"
          else
              echo -e "''${RED}✗ Switch failed''${NC}"
              exit 1
          fi
      else
          echo -e "''${YELLOW}Test configuration not applied. You can run 'nrs-rig' later to switch.''${NC}"
      fi
    '')
    (pkgs.writeScriptBin "hack-up" ''
      #!/usr/bin/env bash
      # Update flake, test Hack configuration, and prompt to switch

      # Colors for output
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      BLUE='\033[0;34m'
      NC='\033[0m' # No Color

      # Error handling
      set -e
      trap 'echo -e "''${RED}Error occurred at line $LINENO. Exiting.''${NC}" >&2' ERR

      # Verify we're in the right directory
      if [ ! -f ~/dotfiles/flake.nix ]; then
          echo -e "''${RED}Error: ~/dotfiles/flake.nix not found''${NC}"
          exit 1
      fi

      cd ~/dotfiles/

      # Update flake
      echo -e "''${BLUE}[1/3] Updating flake inputs...''${NC}"
      if nix flake update; then
          echo -e "''${GREEN}✓ Flake updated successfully''${NC}"
      else
          echo -e "''${RED}✗ Flake update failed''${NC}"
          exit 1
      fi

      # Test configuration
      echo -e "\n''${BLUE}[2/3] Testing Hack configuration...''${NC}"
      if sudo nixos-rebuild test --flake .#Hack; then
          echo -e "''${GREEN}✓ Test completed successfully''${NC}"
      else
          echo -e "''${RED}✗ Test failed! Configuration not applied.''${NC}"
          echo -e "''${YELLOW}Tip: Check the error messages above for details''${NC}"
          exit 1
      fi

      # Prompt to switch
      echo -e "\n''${BLUE}[3/3] Apply configuration?''${NC}"
      echo -e "''${YELLOW}Test successful! Switch to new configuration? [y/N]''${NC} "
      read -r response

      if [[ "$response" =~ ^[Yy]$ ]]; then
          echo -e "''${BLUE}Switching to new configuration...''${NC}"
          if sudo nixos-rebuild switch --flake .#Hack; then
              echo -e "''${GREEN}✓ Successfully switched to Hack configuration!''${NC}"
          else
              echo -e "''${RED}✗ Switch failed''${NC}"
              exit 1
          fi
      else
          echo -e "''${YELLOW}Test configuration not applied. You can run 'nrs-hack' later to switch.''${NC}"
      fi
    '')
    (pkgs.writeScriptBin "guard-up" ''
      #!/usr/bin/env bash
      # Update flake, test Guard configuration, and prompt to switch

      # Colors for output
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      BLUE='\033[0;34m'
      NC='\033[0m' # No Color

      # Error handling
      set -e
      trap 'echo -e "''${RED}Error occurred at line $LINENO. Exiting.''${NC}" >&2' ERR

      # Verify we're in the right directory
      if [ ! -f ~/dotfiles/flake.nix ]; then
          echo -e "''${RED}Error: ~/dotfiles/flake.nix not found''${NC}"
          exit 1
      fi

      cd ~/dotfiles/

      # Update flake
      echo -e "''${BLUE}[1/3] Updating flake inputs...''${NC}"
      if nix flake update; then
          echo -e "''${GREEN}✓ Flake updated successfully''${NC}"
      else
          echo -e "''${RED}✗ Flake update failed''${NC}"
          exit 1
      fi

      # Test configuration
      echo -e "\n''${BLUE}[2/3] Testing Guard configuration...''${NC}"
      if sudo nixos-rebuild test --flake .#Guard; then
          echo -e "''${GREEN}✓ Test completed successfully''${NC}"
      else
          echo -e "''${RED}✗ Test failed! Configuration not applied.''${NC}"
          echo -e "''${YELLOW}Tip: Check the error messages above for details''${NC}"
          exit 1
      fi

      # Prompt to switch
      echo -e "\n''${BLUE}[3/3] Apply configuration?''${NC}"
      echo -e "''${YELLOW}Test successful! Switch to new configuration? [y/N]''${NC} "
      read -r response

      if [[ "$response" =~ ^[Yy]$ ]]; then
          echo -e "''${BLUE}Switching to new configuration...''${NC}"
          if sudo nixos-rebuild switch --flake .#Guard; then
              echo -e "''${GREEN}✓ Successfully switched to Guard configuration!''${NC}"
          else
              echo -e "''${RED}✗ Switch failed''${NC}"
              exit 1
          fi
      else
          echo -e "''${YELLOW}Test configuration not applied. You can run 'nrs-guard' later to switch.''${NC}"
      fi
    '')
    (pkgs.writeScriptBin "stub-up" ''
      #!/usr/bin/env bash
      # Update flake, test Stub configuration, and prompt to switch

      # Colors for output
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      BLUE='\033[0;34m'
      NC='\033[0m' # No Color

      # Error handling
      set -e
      trap 'echo -e "''${RED}Error occurred at line $LINENO. Exiting.''${NC}" >&2' ERR

      # Verify we're in the right directory
      if [ ! -f ~/dotfiles/flake.nix ]; then
          echo -e "''${RED}Error: ~/dotfiles/flake.nix not found''${NC}"
          exit 1
      fi

      cd ~/dotfiles/

      # Update flake
      echo -e "''${BLUE}[1/3] Updating flake inputs...''${NC}"
      if nix flake update; then
          echo -e "''${GREEN}✓ Flake updated successfully''${NC}"
      else
          echo -e "''${RED}✗ Flake update failed''${NC}"
          exit 1
      fi

      # Test configuration
      echo -e "\n''${BLUE}[2/3] Testing Stub configuration...''${NC}"
      if sudo nixos-rebuild test --flake .#Stub; then
          echo -e "''${GREEN}✓ Test completed successfully''${NC}"
      else
          echo -e "''${RED}✗ Test failed! Configuration not applied.''${NC}"
          echo -e "''${YELLOW}Tip: Check the error messages above for details''${NC}"
          exit 1
      fi

      # Prompt to switch
      echo -e "\n''${BLUE}[3/3] Apply configuration?''${NC}"
      echo -e "''${YELLOW}Test successful! Switch to new configuration? [y/N]''${NC} "
      read -r response

      if [[ "$response" =~ ^[Yy]$ ]]; then
          echo -e "''${BLUE}Switching to new configuration...''${NC}"
          if sudo nixos-rebuild switch --flake .#Stub; then
              echo -e "''${GREEN}✓ Successfully switched to Stub configuration!''${NC}"
          else
              echo -e "''${RED}✗ Switch failed''${NC}"
              exit 1
          fi
      else
          echo -e "''${YELLOW}Test configuration not applied. You can run 'nrs-stub' later to switch.''${NC}"
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
