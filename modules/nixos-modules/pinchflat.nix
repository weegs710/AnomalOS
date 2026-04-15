{
  flake.nixosModules.pinchflat = {config, ...}: let
    user = config.mySystem.user.name;
  in {
    services.pinchflat = {
      enable = true;
      port = 8945; # Default port, accessible at http://localhost:8945
      openFirewall = true;
      selfhosted = true;

      # For more options see: https://github.com/kieraneglin/pinchflat/wiki/%5BAdvanced%5D-Custom-yt%E2%80%90dlp-options
      extraConfig = {
        LOG_LEVEL = "info";
      };
    };

    # Create symlink from ~/Videos/pinchflat to the actual media directory
    systemd.tmpfiles.rules = [
      "d /home/${user}/Videos 0755 ${user} users -"
      "L+ /home/${user}/Videos/pinchflat - - - - /var/lib/pinchflat/media"
    ];
  };
}
