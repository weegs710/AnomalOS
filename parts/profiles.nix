# Build Profiles
#
# Profiles allow different feature combinations for different builds/hosts.
# Each profile overrides the defaults set in configuration.nix using mkForce.
#
# Usage: Assigned to hosts in parts/configurations.nix
# Example: Rig uses 'full', Hack uses 'noYubikey', etc.

{lib, ...}: {
  profiles = {
    # ============================================================================
    # Standard Profiles
    # ============================================================================

    # Full Profile - All features enabled (default)
    # Used by: Rig (main desktop)
    # Features: YubiKey, Claude Code, Desktop, Gaming, Development, AI
    full = {};

    # ============================================================================
    # Testing Profiles
    # ============================================================================

    # No YubiKey Profile - For systems without YubiKey hardware
    # Used by: Hack
    # Use case: Testing configuration on systems without YubiKey
    noYubikey = {
      mySystem.features.yubikey = lib.mkForce false;
    };

    # No Claude Code Profile - For systems without Claude Code tooling
    # Used by: Guard
    # Use case: Testing configuration without development tools
    noClaudeCode = {
      mySystem.features.claudeCode = lib.mkForce false;
    };

    # Minimal Profile - Minimal feature set
    # Used by: Stub
    # Use case: Testing core functionality without optional features
    minimal = {
      mySystem.features = {
        yubikey = lib.mkForce false;
        claudeCode = lib.mkForce false;
      };
    };

    # ============================================================================
    # Specialized Profiles
    # ============================================================================

    # Server Profile - Headless server configuration
    # Use case: Server deployments without desktop environment
    server = {
      mySystem.features = {
        desktop = lib.mkForce false;
        gaming = lib.mkForce false;
        claudeCode = lib.mkForce false;
        aiAssistant = lib.mkForce false;
        # Keep: security, development, yubikey
      };
      mySystem.hardware = {
        bluetooth = lib.mkForce false;
        steam = lib.mkForce false;
      };
    };

    # Workstation Profile - Development-focused without gaming
    # Use case: Clean development environment
    workstation = {
      mySystem.features = {
        gaming = lib.mkForce false;
        aiAssistant = lib.mkForce false;
        # Keep: desktop, security, development, claudeCode, yubikey
      };
      mySystem.hardware = {
        steam = lib.mkForce false;
      };
    };
  };
}
