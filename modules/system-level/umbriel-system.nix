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

      hardware.graphics.enable = true;

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

      xdg.portal = {
        enable = true;
        # OpenURI only honours a default for web schemes and inode/directory, so routing xdg-open through it shows an app chooser for every other type regardless of mimeapps
        xdgOpenUsePortal = false;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        # Section key is the runtime XDG_CURRENT_DESKTOP, which the compositor setenvs lowercase.
        config.umbriel.default = [
          "umbriel"
          "gtk"
        ];
      };

      services = {
        xserver.enable = false;
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
