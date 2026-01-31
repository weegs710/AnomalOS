{...}: {
  flake.nixosModules.ghostty = {
    config,
    lib,
    ...
  }:
    with lib; {
      config = mkIf config.mySystem.features.desktop {
        home-manager.users.${config.mySystem.user.name} = {
          programs.ghostty = {
            enable = true;
            settings = {
              scroll-to-bottom = "keystroke";
              copy-on-select = "clipboard";
              window-show-tab-bar = "never";
              theme = "noctalia";
              keybind = [
                "shift+enter=text:\\n"
                "ctrl+v=paste_from_clipboard"
              ];
            };
          };

          xdg.dataFile."applications/com.mitchellh.ghostty.desktop".text = ''
            [Desktop Entry]
            Name=Ghostty
            Comment=Fast, feature-rich terminal emulator
            Keywords=shell;prompt;command;commandline;cmd;
            Icon=com.mitchellh.ghostty
            StartupWMClass=com.mitchellh.ghostty
            TryExec=ghostty
            Exec=ghostty
            Type=Application
            Categories=System;TerminalEmulator;Utility;
            Terminal=false
          '';
        };
      };
    };
}
