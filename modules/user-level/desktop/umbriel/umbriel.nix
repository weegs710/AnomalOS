{
  config,
  lib,
  ...
}:
let
  username = config.mySystem.user.name;
  shaders = "${config.programs.umbriel.package}/share/umbriel/shaders";
in
{
  hjem.users.${username} = {
    # Copied rather than symlinked because noctalia's umbriel template rewrites this file in place to add its [include].
    xdg.config.files."umbriel/config.toml" = {
      source = ./config.toml;
      type = "copy";
      # type=copy lands 444 from the store, and noctalia's template rewrites this file in place
      permissions = "0644";
    };

    # the shaders ship inside the umbriel package, so their path is only known at build time
    xdg.config.files."umbriel/shaders.toml".text = lib.replaceStrings [ "@SHADERS@" ] [ shaders ] (
      builtins.readFile ./shaders.toml
    );
  };

  # umbriel resolves its [include] at startup, before noctalia can regenerate the palette on a wiped root
  preservation.preserveAt."/persist".users.${username}.files = [
    ".config/umbriel/noctalia.toml"
  ];
}
