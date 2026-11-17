{
  only = {
    tags = [ "desktop" ];
  };
  module =
    {
      config,
      inputs,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.umbriel.nixosModules.default ];

      programs.umbriel.enable = true;
      # dpms-reconnect-hold: the HKC drops HDMI hotplug detect ~11s into dpms-off, and the rebuilt output would otherwise power straight back on.
      # scratchpad-open-fade: a window mapping into a scratchpad had its show fade overwritten by windows_in's duration.
      programs.umbriel.package =
        inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
          (old: {
            patches = (old.patches or [ ]) ++ [
              ./umbriel-dpms-reconnect-hold-patch
              ./umbriel-scratchpad-open-fade-patch
            ];
          });

      nix.settings = {
        substituters = [ "https://umbriel.cachix.org" ];
        trusted-public-keys = [ "umbriel.cachix.org-1:JfNq/2yg2S6D6z4Z2dVSZrZlDPQTKtexB6GAVLD98nw=" ];
      };

      xdg.portal = {
        # OpenURI only honours a default for web schemes and inode/directory, so routing xdg-open through it shows an app chooser for every other type regardless of mimeapps
        xdgOpenUsePortal = false;
      };

      users.users.${config.mySystem.user.name}.packages = with pkgs; [
        wl-clipboard
        grim
        satty
      ];

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        # GTK3 apps bypass xdg-portal for file dialogs without this
        GTK_USE_PORTAL = "1";
      };
    };
}
