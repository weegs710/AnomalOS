{ lib, ... }:
{
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

    # `use` is parse-time in nushell, so a tag-gated module cannot guard its own import at runtime
    nushell.extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Nushell config appended by gated modules that ship their own commands";
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
  };
}
