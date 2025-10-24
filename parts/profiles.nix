# Build profiles for different feature combinations

{lib, ...}: {
  profiles = {
    full = {};

    noYubikey = {
      mySystem.features.yubikey = lib.mkForce false;
    };

    noClaudeCode = {
      mySystem.features.claudeCode = lib.mkForce false;
    };

    minimal = {
      mySystem.features = {
        yubikey = lib.mkForce false;
        claudeCode = lib.mkForce false;
      };
    };

    server = {
      mySystem.features = {
        desktop = lib.mkForce false;
        gaming = lib.mkForce false;
        claudeCode = lib.mkForce false;
        aiAssistant = lib.mkForce false;
      };
      mySystem.hardware = {
        bluetooth = lib.mkForce false;
        steam = lib.mkForce false;
      };
    };

    workstation = {
      mySystem.features = {
        gaming = lib.mkForce false;
        aiAssistant = lib.mkForce false;
      };
      mySystem.hardware = {
        steam = lib.mkForce false;
      };
    };
  };
}
