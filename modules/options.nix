# System option definitions for the mySystem namespace
{lib, ...}:
with lib; {
  options.mySystem = {
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

    features = {
      yubikey = mkEnableOption "YubiKey U2F authentication support";
      claudeCode = mkEnableOption "Claude Code development environment";
      gaming = mkEnableOption "Gaming support (Steam, emulators)";
      desktop = mkEnableOption "Desktop environment (Hyprland)";
      development = mkEnableOption "Development tools and languages";
      security = mkEnableOption "Enhanced security features";
      flatpak = mkEnableOption "Declarative Flatpak package management";
      kdeconnect = mkEnableOption "KDE Connect for device integration and file transfer";
      vm = mkEnableOption "Virtual machine support (libvirtd, virt-manager)";
    };

    security = {
      dnscrypt = mkEnableOption "DNSCrypt-Proxy with encrypted DNS (Quad9 + Cloudflare)";
    };

    hardware = {
      amd = mkEnableOption "AMD GPU support";
      nvidia = mkEnableOption "NVIDIA GPU support";
      bluetooth = mkEnableOption "Bluetooth support";
      steam = mkEnableOption "Steam hardware support";
    };
  };
}
