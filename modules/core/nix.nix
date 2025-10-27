{
  config,
  lib,
  pkgs,
  inputs,
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

      # Build performance
      cores = 0; # 0 = use all available cores
      max-jobs = "auto"; # Let Nix decide based on available resources

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

  environment.systemPackages = with pkgs; [
    curl
    git
    wget
    inputs.helium.defaultPackage.${pkgs.system}

    (pkgs.writeScriptBin "rig-up" ''
      #!/usr/bin/env bash
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      BLUE='\033[0;34m'
      NC='\033[0m'

      set -e
      trap 'echo -e "''${RED}Error occurred at line $LINENO. Exiting.''${NC}" >&2' ERR
      if [ ! -f ~/dotfiles/flake.nix ]; then
          echo -e "''${RED}Error: ~/dotfiles/flake.nix not found''${NC}"
          exit 1
      fi

      cd ~/dotfiles/

      echo -e "''${BLUE}[1/3] Updating flake inputs...''${NC}"
      if nix flake update; then
          echo -e "''${GREEN}✓ Flake updated successfully''${NC}"
      else
          echo -e "''${RED}✗ Flake update failed''${NC}"
          exit 1
      fi

      echo -e "\n''${BLUE}[2/3] Testing Rig configuration...''${NC}"
      if nh os test .#nixosConfigurations.Rig; then
          echo -e "''${GREEN}✓ Test completed successfully''${NC}"
      else
          echo -e "''${RED}✗ Test failed! Configuration not applied.''${NC}"
          echo -e "''${YELLOW}Tip: Check the error messages above for details''${NC}"
          exit 1
      fi

      echo -e "\n''${BLUE}[3/3] Apply configuration?''${NC}"
      echo -e "''${YELLOW}Test successful! Switch to new configuration? [y/N]''${NC} "
      read -r response

      if [[ "$response" =~ ^[Yy]$ ]]; then
          echo -e "''${BLUE}Switching to new configuration...''${NC}"
          if nh os switch .#nixosConfigurations.Rig; then
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
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      BLUE='\033[0;34m'
      NC='\033[0m'

      set -e
      trap 'echo -e "''${RED}Error occurred at line $LINENO. Exiting.''${NC}" >&2' ERR
      if [ ! -f ~/dotfiles/flake.nix ]; then
          echo -e "''${RED}Error: ~/dotfiles/flake.nix not found''${NC}"
          exit 1
      fi

      cd ~/dotfiles/

      echo -e "''${BLUE}[1/3] Updating flake inputs...''${NC}"
      if nix flake update; then
          echo -e "''${GREEN}✓ Flake updated successfully''${NC}"
      else
          echo -e "''${RED}✗ Flake update failed''${NC}"
          exit 1
      fi

      echo -e "\n''${BLUE}[2/3] Testing Hack configuration...''${NC}"
      if nh os test .#nixosConfigurations.Hack; then
          echo -e "''${GREEN}✓ Test completed successfully''${NC}"
      else
          echo -e "''${RED}✗ Test failed! Configuration not applied.''${NC}"
          echo -e "''${YELLOW}Tip: Check the error messages above for details''${NC}"
          exit 1
      fi

      echo -e "\n''${BLUE}[3/3] Apply configuration?''${NC}"
      echo -e "''${YELLOW}Test successful! Switch to new configuration? [y/N]''${NC} "
      read -r response

      if [[ "$response" =~ ^[Yy]$ ]]; then
          echo -e "''${BLUE}Switching to new configuration...''${NC}"
          if nh os switch .#nixosConfigurations.Hack; then
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
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      BLUE='\033[0;34m'
      NC='\033[0m'

      set -e
      trap 'echo -e "''${RED}Error occurred at line $LINENO. Exiting.''${NC}" >&2' ERR
      if [ ! -f ~/dotfiles/flake.nix ]; then
          echo -e "''${RED}Error: ~/dotfiles/flake.nix not found''${NC}"
          exit 1
      fi

      cd ~/dotfiles/

      echo -e "''${BLUE}[1/3] Updating flake inputs...''${NC}"
      if nix flake update; then
          echo -e "''${GREEN}✓ Flake updated successfully''${NC}"
      else
          echo -e "''${RED}✗ Flake update failed''${NC}"
          exit 1
      fi

      echo -e "\n''${BLUE}[2/3] Testing Guard configuration...''${NC}"
      if nh os test .#nixosConfigurations.Guard; then
          echo -e "''${GREEN}✓ Test completed successfully''${NC}"
      else
          echo -e "''${RED}✗ Test failed! Configuration not applied.''${NC}"
          echo -e "''${YELLOW}Tip: Check the error messages above for details''${NC}"
          exit 1
      fi

      echo -e "\n''${BLUE}[3/3] Apply configuration?''${NC}"
      echo -e "''${YELLOW}Test successful! Switch to new configuration? [y/N]''${NC} "
      read -r response

      if [[ "$response" =~ ^[Yy]$ ]]; then
          echo -e "''${BLUE}Switching to new configuration...''${NC}"
          if nh os switch .#nixosConfigurations.Guard; then
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
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      BLUE='\033[0;34m'
      NC='\033[0m'

      set -e
      trap 'echo -e "''${RED}Error occurred at line $LINENO. Exiting.''${NC}" >&2' ERR
      if [ ! -f ~/dotfiles/flake.nix ]; then
          echo -e "''${RED}Error: ~/dotfiles/flake.nix not found''${NC}"
          exit 1
      fi

      cd ~/dotfiles/

      echo -e "''${BLUE}[1/3] Updating flake inputs...''${NC}"
      if nix flake update; then
          echo -e "''${GREEN}✓ Flake updated successfully''${NC}"
      else
          echo -e "''${RED}✗ Flake update failed''${NC}"
          exit 1
      fi

      echo -e "\n''${BLUE}[2/3] Testing Stub configuration...''${NC}"
      if nh os test .#nixosConfigurations.Stub; then
          echo -e "''${GREEN}✓ Test completed successfully''${NC}"
      else
          echo -e "''${RED}✗ Test failed! Configuration not applied.''${NC}"
          echo -e "''${YELLOW}Tip: Check the error messages above for details''${NC}"
          exit 1
      fi

      echo -e "\n''${BLUE}[3/3] Apply configuration?''${NC}"
      echo -e "''${YELLOW}Test successful! Switch to new configuration? [y/N]''${NC} "
      read -r response

      if [[ "$response" =~ ^[Yy]$ ]]; then
          echo -e "''${BLUE}Switching to new configuration...''${NC}"
          if nh os switch .#nixosConfigurations.Stub; then
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

  environment.shellAliases = {
    nfa = "cd ~/dotfiles/ && nix flake archive";
    recycle = "sudo nix-env --delete-generations +10 --profile /nix/var/nix/profiles/system && sudo nix-collect-garbage";
    update = "cd ~/dotfiles/ && nix flake update";
    closure = "nix path-info -Sh /run/current-system";
    shh = "tmux new -d 'env STEAM_FRAME_FORCE_CLOSE=1 steam -silent'";

    nrs-rig = "cd ~/dotfiles/ && nh os switch .#nixosConfigurations.Rig";
    nrt-rig = "cd ~/dotfiles/ && nh os test .#nixosConfigurations.Rig";
    nrs-hack = "cd ~/dotfiles/ && nh os switch .#nixosConfigurations.hack";
    nrt-hack = "cd ~/dotfiles/ && nh os test .#nixosConfigurations.hack";
    nrs-guard = "cd ~/dotfiles/ && nh os switch .#nixosConfigurations.guard";
    nrt-guard = "cd ~/dotfiles/ && nh os test .#nixosConfigurations.guard";
    nrs-stub = "cd ~/dotfiles/ && nh os switch .#nixosConfigurations.stub";
    nrt-stub = "cd ~/dotfiles/ && nh os test .#nixosConfigurations.stub";
  };
}
