{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.desktop {
    home.packages = with pkgs; [
      nemo-with-extensions
      nemo-preview
    ];

    dconf.settings = {
      "org/cinnamon/desktop/applications/terminal" = {
        exec = "ghostty";
      };

      "org/nemo/window-state" = {
        side-pane-view = "tree";
      };

      "org/nemo/preferences" = {
        default-folder-viewer = "list-view";
        show-image-thumbnails = "always";
      };
    };
  };
}
