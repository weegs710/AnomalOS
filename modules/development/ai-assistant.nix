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

  # Create klank command to open Web UI in browser
  klank = pkgs.writeShellScriptBin "klank" ''
    #!/usr/bin/env bash

    # Open browser to Open WebUI (services auto-start on boot)
    ${pkgs.xdg-utils}/bin/xdg-open http://localhost:8080 2>/dev/null &
  '';

  # Create klank-cli command to launch CLI assistant
  klank-cli = pkgs.writeShellScriptBin "klank-cli" ''
    #!/usr/bin/env bash

    # Colors
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m'

    echo -e "''${BLUE}╔══════════════════════════════════════════════════════╗''${NC}"
    echo -e "''${BLUE}║             KLANK AI ASSISTANT - CLI                 ║''${NC}"
    echo -e "''${BLUE}╚══════════════════════════════════════════════════════╝''${NC}"
    echo ""

    # Check if ollama service is running
    if ! systemctl --user is-active --quiet ollama.service; then
      echo -e "''${YELLOW}⚠️  Ollama service not running. Starting...''${NC}"
      systemctl --user start ollama.service
      sleep 2
    fi

    echo -e "''${GREEN}✓ Ollama service: ''${NC}$(systemctl --user is-active ollama.service)"
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
    # Create user services for ollama and open-webui (no sudo required)
    systemd.user.services.ollama = {
      description = "Ollama LLM Service (User)";
      after = ["network.target"];

      serviceConfig = {
        Type = "simple";
        # Using CPU-only ollama to avoid lengthy ROCm compilation
        ExecStart = "${pkgs.ollama}/bin/ollama serve";
        Restart = "on-failure";
        RestartSec = "5s";
        Environment = [
          "OLLAMA_HOST=127.0.0.1:11434"
          "OLLAMA_NUM_CTX=32000"
        ];
      };

      wantedBy = ["default.target"];
    };

    systemd.user.services.open-webui = {
      description = "Open WebUI (User)";
      after = ["network.target"];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.open-webui}/bin/open-webui serve --host 127.0.0.1 --port 8080";
        Restart = "on-failure";
        RestartSec = "5s";
        Environment = [
          "OLLAMA_BASE_URL=http://127.0.0.1:11434"
          "WEBUI_AUTH=False"
          "ENABLE_RAG_WEB_SEARCH=False"
          "ENABLE_CODE_EXECUTION=True"
          "CODE_EXECUTION_TIMEOUT=30"
          "DATA_DIR=%h/.local/share/open-webui/data"
          "HF_HOME=%h/.cache/huggingface"
          "SENTENCE_TRANSFORMERS_HOME=%h/.cache/sentence-transformers"
          "STATIC_DIR=%h/.local/share/open-webui/static"
        ];
      };

      # Auto-start on boot
      wantedBy = ["default.target"];
    };

    # Add user to ollama and render groups (render needed for GPU access)
    users.users.${userName}.extraGroups = ["ollama" "render" "video"];

    # Install system packages
    environment.systemPackages = with pkgs;
      [
        # Ollama (CPU-only to avoid ROCm compilation)
        ollama

        # klank command to open Web UI in browser
        klank

        # klank-cli command to launch CLI assistant
        klank-cli

        # Model deployment script
        deployModels
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
      ai = "klank-cli";
      ai-cli = "klank-cli";
      ai-web = "klank";
    };
  };
}
