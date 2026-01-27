{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) filter hasInfix mkOption;
in {
  # User account configuration - always enabled (core system feature)
  # Includes: root and primary user accounts, persisted passwords, fish shell

  options = {
    warnings = mkOption {
      apply = filter (w: !(hasInfix "If multiple of these password options are set at the same time" w));
    };
  };

  config = {
    users = {
      mutableUsers = true;
      defaultUserShell = pkgs.fish;

      users = {
        root = {
          initialPassword = "password";
          hashedPasswordFile = "/persist/etc/shadow/root";
        };

        ${config.mySystem.user.name} = {
          isNormalUser = true;
          initialPassword = "password";
          hashedPasswordFile = "/persist/etc/shadow/${config.mySystem.user.name}";
          description = config.mySystem.user.description;
          extraGroups = config.mySystem.user.extraGroups;
          packages = with pkgs; [
          ];
        };
      };
    };

    # Basic shell setup
    programs.fish.enable = true;
  };
}
