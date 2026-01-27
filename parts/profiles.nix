{lib, ...}: {
  profiles = {
    full = {};

    server = {
      mySystem.features = {
        desktop = lib.mkForce false;
        gaming = lib.mkForce false;
        claudeCode = lib.mkForce false;
      };
      mySystem.hardware = {
        bluetooth = lib.mkForce false;
        steam = lib.mkForce false;
      };
    };

    workstation = {
      mySystem.features = {
        gaming = lib.mkForce false;
      };
      mySystem.hardware = {
        steam = lib.mkForce false;
      };
    };
  };
}
