# System Options Definition
#
# This module defines all configurable options for the mySystem namespace.
# These options are set in configuration.nix and control which features are enabled.
#
# Usage:
#   mySystem.features.desktop = true;
#   mySystem.user.name = "username";
#   mySystem.hardware.amd = true;

{ lib, ... }:

with lib;

{
  options.mySystem = {
    # User configuration
    user = {
      name = mkOption {
        type = types.str;
        default = "anomalos";
        description = "Primary username for the system";
      };

      description = mkOption {
        type = types.str;
        default = "AnomalOS User";
        description = "User description";
      };

      extraGroups = mkOption {
        type = types.listOf types.str;
        default = [
          "networkmanager"
          "wheel"
        ];
        description = "Additional groups for the user";
      };
    };

    # System configuration
    hostName = mkOption {
      type = types.str;
      default = "anomalos";
      description = "System hostname";
    };

    timeZone = mkOption {
      type = types.str;
      default = "America/New_York";
      description = "System timezone";
    };

    # Optional features
    features = {
      yubikey = mkEnableOption "YubiKey U2F authentication support";
      claudeCode = mkEnableOption "Claude Code development environment";
      gaming = mkEnableOption "Gaming support (Steam, emulators)";
      desktop = mkEnableOption "Desktop environment (Hyprland)";
      development = mkEnableOption "Development tools and languages";
      security = mkEnableOption "Enhanced security features";
      # Note: aiAssistant is declared in modules/development/ai-assistant.nix
    };

    # Hardware features
    hardware = {
      amd = mkEnableOption "AMD GPU support";
      nvidia = mkEnableOption "NVIDIA GPU support";
      bluetooth = mkEnableOption "Bluetooth support";
      steam = mkEnableOption "Steam hardware support";
    };
  };
}
