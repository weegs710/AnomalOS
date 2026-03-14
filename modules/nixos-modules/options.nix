{
  flake.nixosModules.options = {lib, ...}: {
    options.mySystem = {
      user = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "anomalos";
          description = "Primary username for the system";
        };

        description = lib.mkOption {
          type = lib.types.str;
          default = "AnomalOS User";
          description = "User description";
        };

        extraGroups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "networkmanager"
            "wheel"
          ];
          description = "Additional groups for the user";
        };
      };

      hostName = lib.mkOption {
        type = lib.types.str;
        default = "anomalos";
        description = "System hostname";
      };

      timeZone = lib.mkOption {
        type = lib.types.str;
        default = "America/New_York";
        description = "System timezone";
      };

      features = {
        yubikey = lib.mkEnableOption "YubiKey U2F authentication support";
        aiTooling = lib.mkEnableOption "AI tooling (Claude Code and related tools)";
        gaming = lib.mkEnableOption "Gaming support (Steam, emulators)";
        desktop = lib.mkEnableOption "Desktop environment (Hyprland)";
        development = lib.mkEnableOption "Development tools and languages";
        media = lib.mkEnableOption "Media tools (audio, video, creation)";
      };

      hardware = {
        amd = lib.mkEnableOption "AMD GPU support";
        nvidia = lib.mkEnableOption "NVIDIA GPU support";
        bluetooth = lib.mkEnableOption "Bluetooth support";
        steam = lib.mkEnableOption "Steam hardware support";
      };
    };
  };
}
