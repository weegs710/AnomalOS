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
    };
    stylix.targets.yazi.enable = false;
  };
}
