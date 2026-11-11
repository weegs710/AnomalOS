{ config, ... }:
{
  # umbriel and noctalia both merge these over their shared config, so only this machine's monitors and devices live here
  hjem.users.${config.mySystem.user.name}.xdg.config.files = {
    "umbriel/host.toml".source = ./umbriel-host.toml;
    "noctalia/host.toml".source = ./noctalia-host.toml;
  };
}
