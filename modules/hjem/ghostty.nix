{...}: {
  flake.nixosModules.ghostty = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; {
      config = mkIf config.mySystem.features.desktop {
        users.users.${config.mySystem.user.name}.packages = [pkgs.ghostty];

        hjem.users.${config.mySystem.user.name} = {
          xdg.config.files."ghostty/config".text = ''
            scroll-to-bottom = keystroke
            copy-on-select = clipboard
            window-show-tab-bar = never
            theme = noctalia

            keybind = shift+enter=text:\n
            keybind = ctrl+v=paste_from_clipboard

            # Unbind terminal shortcuts that conflict with flow-control editor
            keybind = ctrl+q=unbind
            keybind = ctrl+w=unbind
            keybind = ctrl+tab=unbind
            keybind = ctrl+shift+tab=unbind
          '';

          xdg.data.files."applications/com.mitchellh.ghostty.desktop".text = ''
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
