{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
  umbrielBin = "${config.programs.umbriel.package}/bin/umbriel";
  zedIcons = pkgs.writers.writeNuBin "zed-icons" (builtins.readFile ./zed-icons.nu);
in
{
  hjem.extraModules = [ inputs.noctalia.hjemModules.default ];

  environment.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };

  # noctalia writes runtime state + git-cloned plugin/palette caches here; persist it so the tmpfs root reboot doesn't re-clone every boot
  preservation.preserveAt."/persist".users.${username}.directories = [
    ".local/state/noctalia"
  ];

  hjem.users.${username} = {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };

    # umbriel publishes the session environment after graphical-session.target activates, so the unit inherits none of it
    systemd.services.noctalia.environment.UMBRIEL_SOCKET = "%t/umbriel-wayland-0.sock";

    # settings left empty so config.toml stays a standalone first-class file (copied, not nix-generated); v5 hot-reloads it via inotify
    xdg.config.files."noctalia/config.toml" = {
      source = ./config.toml;
      type = "copy";
      clobber = false;
    };

    # hooks are read from any *.toml here, so they stay out of the config.toml noctalia writes back to
    xdg.config.files."noctalia/hooks.toml".text = lib.replaceStrings [ "@UMBRIEL@" ] [ umbrielBin ] (
      builtins.readFile ./hooks.toml
    );

    # user templates load from any *.toml here, same as hooks; the hook needs the script's store path
    xdg.config.files."noctalia/zed-icons.toml".text = lib.replaceStrings [ "@ZED_ICONS@" ] [
      "${zedIcons}/bin/zed-icons"
    ] (builtins.readFile ./zed-icons.toml);
    xdg.config.files."noctalia/templates/zed-icon-colors.json".source = ./templates/zed-icon-colors.json;
    xdg.config.files."noctalia/claude-code.toml".source = ./claude-code.toml;
    xdg.config.files."noctalia/templates/claude-code.json".source = ./templates/claude-code.json;
    xdg.config.files."noctalia/discord.toml".source = ./discord.toml;
    xdg.config.files."noctalia/templates/discord-material.css".source = ./templates/discord-material.css;

    # qt6ct ships no config; without an icon theme Qt resolves named icons to the missing-icon checker
    xdg.config.files."qt6ct/qt6ct.conf".source = ./qt6ct.conf;

    xdg.config.files."noctalia/palettes/Twilight.json".source = ./palettes/Twilight.json;
    xdg.config.files."noctalia/palettes/Plasm.json".source = ./palettes/Plasm.json;
    xdg.config.files."noctalia/palettes/Great-Below.json".source = ./palettes/Great-Below.json;
    xdg.config.files."noctalia/palettes/Cold-Wind.json".source = ./palettes/Cold-Wind.json;
    xdg.config.files."noctalia/palettes/Cymagentan.json".source = ./palettes/Cymagentan.json;
    xdg.config.files."noctalia/palettes/alliance-tournament-xxi-48-vib.json".source = ./palettes/alliance-tournament-xxi-48-vib.json;
    xdg.config.files."noctalia/palettes/Triglavian.json".source = ./palettes/Triglavian.json;
  };
}
