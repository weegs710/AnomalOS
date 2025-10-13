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
  };
}
