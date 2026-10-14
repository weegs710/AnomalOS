{
  config,
  lib,
  pkgs,
  weegsware,
  ...
}:
let
  username = config.mySystem.user.name;

  tfm = weegsware.tfm;

  # the terminal is called by name so the installed one wins, and kitty takes its command positionally with no -e
  chooserWrapper = pkgs.writeTextFile {
    name = "tfm-wrapper.nu";
    executable = true;
    text =
      lib.replaceStrings
        [
          "@NUSHELL@"
          "@TERM@"
          "@TFM@"
          "@CHOOSERCONF@"
        ]
        [
          "${pkgs.nushell}"
          "kitty"
          "${tfm}/bin/tfm"
          "${./chooser.toml}"
        ]
        (builtins.readFile ./tfm-wrapper.nu);
  };
in
{
  users.users.${username}.packages = [ tfm ];

  hjem.users.${username} = {
    xdg.config.files = {
      # the settings panel rewrites this file, so it lands as a real 0644 copy rather than a store symlink
      "tfm/config.toml" = {
        source = ./config.toml;
        type = "copy";
        permissions = "0644";
      };

      # the plugin loader lstats each entry and skips symlinks, so a linked .ts hashes to an empty folder and never loads
      "tfm/plugins/chooser/chooser.ts" = {
        source = ./plugins/chooser/chooser.ts;
        type = "copy";
      };
      "tfm/plugins/archive-extra/archive-extra.ts" = {
        source = ./plugins/archive-extra/archive-extra.ts;
        type = "copy";
      };

      "xdg-desktop-portal-termfilechooser/config".text =
        lib.replaceStrings [ "@WRAPPER@" ] [ "${chooserWrapper}" ]
          (builtins.readFile ./termfilechooser-config);
    };

    xdg.data.files."applications/tfm.desktop".source = ./tfm.desktop;
  };

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/tfm"
    ".local/state/tfm"
  ];
}
