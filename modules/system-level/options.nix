{ lib, pkgs, ... }:
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

    display = {
      width = lib.mkOption {
        type = lib.types.int;
        description = "Primary monitor width in pixels";
      };

      height = lib.mkOption {
        type = lib.types.int;
        description = "Primary monitor height in pixels";
      };

      refresh = lib.mkOption {
        type = lib.types.int;
        description = "Primary monitor refresh rate in Hz";
      };
    };

    paths.games = lib.mkOption {
      type = lib.types.str;
      description = "Root of the games library mount";
    };

    audio.monitorSource = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "PipeWire monitor source visualizers listen to; null uses the default";
    };

    btopPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.btop;
      defaultText = lib.literalExpression "pkgs.btop";
      description = "btop build; a GPU host can pick a variant";
    };
  };
}
