{
  config,
  lib,
  ...
}:
let
  inherit (lib) filter hasInfix mkOption;
in
{
  options = {
    warnings = mkOption {
      apply = filter (w: !(hasInfix "If multiple of these password options are set at the same time" w));
    };
  };

  config = {
    users = {
      mutableUsers = false;
      # Keep bash as login shell (POSIX-compliant, proper env setup)
      # Auto-exec into nushell for interactive sessions (see programs.bash below)

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
          packages = [
          ];
        };
      };
    };

    # Bash auto-exec to nushell is handled via ~/.bashrc (see modules/user-level/bash/)
    # Keeps bash as login shell for POSIX compliance and proper env setup
  };
}
