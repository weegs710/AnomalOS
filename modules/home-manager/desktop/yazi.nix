{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.desktop {
    programs.yazi = {
      enable = true;
      enableFishIntegration = true;
      keymap = builtins.fromTOML (builtins.readFile ./yazi/keymap.toml);
      settings = builtins.fromTOML (builtins.readFile ./yazi/yazi.toml);

      plugins = {
        mount =
          pkgs.fetchFromGitHub {
            owner = "yazi-rs";
            repo = "plugins";
            rev = "19dc890e33b8922eb1a3a165e685436ec4ac0a59";
            sha256 = "sha256-Hml7n07G6tEOPUPOFN9jf01C5LtZRO8pfERVHKHJQRo=";
          }
          + "/mount.yazi";
        git =
          pkgs.fetchFromGitHub {
            owner = "yazi-rs";
            repo = "plugins";
            rev = "19dc890e33b8922eb1a3a165e685436ec4ac0a59";
            sha256 = "sha256-Hml7n07G6tEOPUPOFN9jf01C5LtZRO8pfERVHKHJQRo=";
          }
          + "/git.yazi";
      };

      initLua = ''
        require("git"):setup()
      '';

      # Override Stylix theme background
      theme = {
        mgr = {
          bg = lib.mkForce "#\${config.lib.stylix.colors.base00}";
        };
        status = {
          separator_open = lib.mkForce "";
          separator_close = lib.mkForce "";
          separator_style = lib.mkForce {
            fg = "#\${config.lib.stylix.colors.base00}";
            bg = "#\${config.lib.stylix.colors.base00}";
          };
        };
        which = {
          mask = {
            bg = lib.mkForce "#\${config.lib.stylix.colors.base00}";
          };
        };
      };
    };
    stylix.targets.yazi.enable = true;
  };
}
