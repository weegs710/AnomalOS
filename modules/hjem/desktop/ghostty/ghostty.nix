{
  config,
  pkgs,
  ...
}:
let
  ghostty = pkgs.ghostty.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./ghostty-cursor-debounce-patch ];
  });
in
{
  users.users.${config.mySystem.user.name}.packages = [ ghostty ];

  hjem.users.${config.mySystem.user.name} = {
    xdg.config.files."ghostty/config".source = ./ghostty-config;
    xdg.config.files."ghostty/shaders/cursor_tail.glsl".source = ./cursor_tail.glsl;
    xdg.data.files."applications/com.mitchellh.ghostty.desktop".source =
      ./com.mitchellh.ghostty.desktop;
  };

  preservation.preserveAt."/persist".users.${config.mySystem.user.name}.directories = [
    ".config/ghostty"
  ];
}
