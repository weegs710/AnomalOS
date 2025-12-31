{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.desktop {
    stylix.targets.hyprland.enable = true;

    services.swww = {
      enable = true;
    };

    systemd.user.services.set-wallpaper = {
      Unit = {
        Description = "Set initial Hyprland wallpaper";
        After = ["swww.service"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = let
          script = pkgs.writeShellScript "set-wallpaper" ''
            # Wait for swww daemon to be ready
            for i in {1..30}; do
              if ${pkgs.swww}/bin/swww query &>/dev/null; then
                break
              fi
              sleep 0.5
            done

            # Set wallpaper
            ${pkgs.swww}/bin/swww img ~/.local/share/wallpapers/borg-head.webp --resize stretch 2>/dev/null || true
            ln -sf ~/.local/share/wallpapers/borg-head.webp ~/.cache/hyprlock-wallpaper
          '';
        in "${script}";
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    home.file.".local/bin/rotate-wallpaper.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        wallpaper_dir="$HOME/.local/share/wallpapers"
        cache_link="$HOME/.cache/hyprlock-wallpaper"

        mapfile -t wallpapers < <(find "$wallpaper_dir" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \))

        if [ ''${#wallpapers[@]} -gt 0 ]; then
          image="''${wallpapers[RANDOM % ''${#wallpapers[@]}]}"

          ${pkgs.swww}/bin/swww img "$image" \
            --resize stretch \
            --transition-type wave \
            --transition-duration 2 \
            2>/dev/null || true

          ln -sf "$image" "$cache_link"
        fi
      '';
    };

    systemd.user.services.rotate-wallpaper = {
      Unit = {
        Description = "Rotate wallpaper";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "%h/.local/bin/rotate-wallpaper.sh";
        Type = "oneshot";
      };
    };

    systemd.user.timers.rotate-wallpaper = {
      Unit = {
        Description = "Rotate wallpaper every minute";
        Requires = ["rotate-wallpaper.service"];
      };
      Timer = {
        OnBootSec = "1m";
        OnUnitActiveSec = "1m";
        AccuracySec = "1m";
        Persistent = true;
      };
      Install = {
        WantedBy = ["timers.target"];
      };
    };
  };
}
