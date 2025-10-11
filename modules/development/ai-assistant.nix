{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  userName = config.mySystem.user.name;
  userHome = config.users.users.${userName}.home;
  assetsDir = "/etc/nixos/assets/ai-assistant"; # System-wide assets

  # Create klank command to launch CLI assistant
  klank = pkgs.writeShellScriptBin "klank" ''
    #!/usr/bin/env bash

    # Colors
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m'

    echo -e "''${BLUE}╔══════════════════════════════════════════════════════╗''${NC}"
    echo -e "''${BLUE}║                KLANK AI ASSISTANT                    ║''${NC}"
    echo -e "''${BLUE}╚══════════════════════════════════════════════════════╝''${NC}"
    echo ""

    # Check if ollama service is running
    if ! systemctl is-active --quiet ollama.service; then
      echo -e "''${YELLOW}⚠️  Ollama service not running. Starting...''${NC}"
      sudo systemctl start ollama.service
      sleep 2
    fi

    echo -e "''${GREEN}✓ Ollama service: ''${NC}$(systemctl is-active ollama.service)"
    echo ""

    # Get the base model that nix-expert uses
    BASE_MODEL=$(${pkgs.ollama}/bin/ollama show nix-expert --modelfile 2>/dev/null | grep "^FROM" | head -1 | cut -d' ' -f2 | xargs basename)

    if [ -n "$BASE_MODEL" ]; then
      echo -e "''${GREEN}🤖 nix-expert base model: ''${NC}$BASE_MODEL"
    else
      echo -e "''${GREEN}🤖 Loading nix-expert model...''${NC}"
    fi
    echo ""

    # Launch nix-expert
    exec ${pkgs.ollama}/bin/ollama run nix-expert
  '';

  # Model deployment script
  deployModels = pkgs.writeShellScriptBin "deploy-ai-models" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo "🤖 Deploying AI assistant models..."

    # Wait for Ollama to be ready
    timeout=60
    while ! ${pkgs.curl}/bin/curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1 && [ $timeout -gt 0 ]; do
      echo "Waiting for Ollama service..."
      sleep 1
      ((timeout--))
    done

    if [ $timeout -eq 0 ]; then
      echo "❌ Ollama service failed to start"
      exit 1
    fi

    # Process nix-expert model from Modelfile
    if [ -f "${assetsDir}/Modelfile-nix-expert" ]; then
      # Extract base model from Modelfile
      BASE_MODEL=$(grep "^FROM" "${assetsDir}/Modelfile-nix-expert" | head -1 | awk '{print $2}')

      if [ -n "$BASE_MODEL" ]; then
        # Check if base model exists, pull if not
        if ! ${pkgs.ollama}/bin/ollama list | grep -q "$BASE_MODEL"; then
          echo "📦 Pulling base model: $BASE_MODEL..."
          ${pkgs.ollama}/bin/ollama pull "$BASE_MODEL"
          echo "✓ Base model pulled"
        else
          echo "✓ Base model $BASE_MODEL already exists"
        fi

        # Check if nix-expert model exists
        if ${pkgs.ollama}/bin/ollama list | grep -q "nix-expert"; then
          echo "🔄 Removing existing nix-expert model for rebuild..."
          ${pkgs.ollama}/bin/ollama rm nix-expert
        fi

        echo "📦 Creating nix-expert model from Modelfile..."
        ${pkgs.ollama}/bin/ollama create nix-expert -f "${assetsDir}/Modelfile-nix-expert"
        echo "✓ nix-expert model created"
      else
        echo "⚠️  Could not extract base model from Modelfile"
      fi
    else
      echo "⚠️  Modelfile not found at ${assetsDir}/Modelfile-nix-expert"
    fi

    echo "✓ Model deployment complete"
  '';
in {
  options.mySystem.features.aiAssistant = mkEnableOption "AI coding assistant (Ollama + Open WebUI)";

  config = mkIf config.mySystem.features.aiAssistant {
    # Enable Ollama service with auto-start and GPU acceleration
    services.ollama = {
      enable = true;
      acceleration =
        if config.mySystem.hardware.nvidia
        then "cuda"
        else if config.mySystem.hardware.amd
        then "rocm"
        else null;

      # Use ROCm-enabled package for AMD
      package =
        if config.mySystem.hardware.amd
        then pkgs.ollama-rocm
        else pkgs.ollama;

      # ROCm environment variables
      environmentVariables = mkIf config.mySystem.hardware.amd {
        HSA_OVERRIDE_GFX_VERSION = "10.3.0"; # For RX 6600/6600 XT (Navi 23)
        HIP_VISIBLE_DEVICES = "0"; # Use GPU[0] (dedicated GPU)
        ROCR_VISIBLE_DEVICES = "0"; # Ensure ROCm uses correct GPU
        OLLAMA_DEBUG = "1";

        # Performance optimization - Pure CPU/RAM inference
        OLLAMA_GPU_LAYERS = "0"; # Full model in RAM, no GPU
        OLLAMA_NUM_PARALLEL = "1"; # Single user, less overhead
        OLLAMA_MAX_LOADED_MODELS = "1"; # Only keep one model in memory
        OLLAMA_KEEP_ALIVE = "0"; # Unload immediately after exit
      };
    };

    # Add user to ollama and render groups (render needed for GPU access)
    users.users.${userName}.extraGroups = ["ollama" "render" "video"];

    # Install system packages
    environment.systemPackages = with pkgs;
      [
        # Ollama (CLI uses same package as service)
        (
          if config.mySystem.hardware.amd
          then ollama-rocm
          else ollama
        )

        # klank command to launch CLI assistant
        klank

        # Model deployment script
        deployModels

        # ROCm tools for AMD GPU
      ]
      ++ lib.optionals config.mySystem.hardware.amd [
        rocmPackages.rocm-smi
        rocmPackages.rocminfo
      ];

    # Copy assets from dotfiles to system location
    environment.etc = {
      "nixos/assets/ai-assistant/Modelfile-nix-expert" = {
        source = ../../assets/ai-assistant/Modelfile-nix-expert;
        mode = "0644";
      };
    };

    # System tuning for LLM performance
    boot.kernel.sysctl = {
      "kernel.shmmax" = 68719476736; # 64GB shared memory
      "kernel.shmall" = 4294967296; # 16GB in pages
      "vm.swappiness" = 10; # Reduce swapping
    };

    # ROCm configuration for AMD GPUs
    systemd.services.ollama = mkIf config.mySystem.hardware.amd {
      serviceConfig = {
        # Ensure GPU access
        SupplementaryGroups = ["render" "video"];
      };
    };

    # Enable hardware acceleration
    hardware.graphics = mkIf config.mySystem.hardware.amd {
      enable = true;
      enable32Bit = true;
    };

    # Environment variables
    environment.variables = {
      OLLAMA_HOST = "127.0.0.1:11434";
      OLLAMA_NUM_CTX = "32000";
    };

    # Tmpfiles for directories
    systemd.tmpfiles.rules = [
      "d /var/lib/ollama 0755 ollama ollama -"
    ];

    # Add helpful shell aliases
    environment.shellAliases = {
      ai = "ollama run nix-expert";
      ai-cli = "ollama run nix-expert";
      ai-web = "klank";
    };
  };
}
