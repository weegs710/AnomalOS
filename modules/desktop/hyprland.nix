{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.desktop {
    # Hyprland and related programs
    programs = {
      hyprland = {
        enable = true;
        xwayland.enable = true;
      };
      hyprlock.enable = true;
      waybar.enable = false; # Configured in home-manager
    };

    services = {
      hypridle.enable = true;
      xserver.enable = false; # We're using Wayland
    };

    # Hyprland-specific Wayland utilities
    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      grim
      hyprshot
      slurp
      swww
      wl-clipboard
      wl-clip-persist
      wlogout
      wlsunset
    ];

    # Environment variables for Wayland
    environment.sessionVariables = {
      # Already set in home.nix, but ensuring they're available system-wide
      NIXOS_OZONE_WL = "1";
    };
  };
}
