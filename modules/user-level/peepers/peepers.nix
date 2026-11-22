{ config, only, ... }:
let
  username = config.mySystem.user.name;
in
only.gate { tags = [ "desktop" ]; } {
  # settings and benchmark history
  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/peepers"
    ".local/state/peepers"
  ];

  # copy-type and writable: peepers saves its settings in place, which a read-only store link would refuse; gui edits get pulled back with `peep-s`
  hjem.users.${username}.xdg.config.files = {
    "peepers/settings.toml" = {
      source = ./settings.toml;
      type = "copy";
      clobber = false;
      permissions = "0644";
    };

    # noctalia renders the colours peepers' Noctalia theme reads; the template comes from the checkout until peepers is packaged
    "noctalia/peepers.toml".text = ''
      [theme.templates.user.peepers]
      input_path  = "~/claude-projects/peepers/packaging/noctalia/colors.toml"
      output_path = "$XDG_CONFIG_HOME/peepers/noctalia.toml"
    '';
  };
}
