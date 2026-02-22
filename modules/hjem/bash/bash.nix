{...}: {
  flake.nixosModules.bash = {config, ...}: {
    # Install ~/.bashrc for auto-exec into nushell
    # Provides escape hatch via BASH_NO_NU env var
    # Prevents recursion via NUSHELL env var and parent process check
    hjem.users.${config.mySystem.user.name}.files = {
      ".bashrc".source = ./bashrc.bash;
    };
  };
}
