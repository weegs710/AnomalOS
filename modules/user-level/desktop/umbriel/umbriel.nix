{
  config,
  lib,
  ...
}:
let
  username = config.mySystem.user.name;
  effects = "${config.programs.umbriel.package}/share/umbriel/effects";
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

    # the effect presets ship inside the umbriel package, so their path is only known at build time
    xdg.config.files."umbriel/shaders.toml".text = lib.replaceStrings [ "@EFFECTS@" ] [ effects ] (
      builtins.readFile ./shaders.toml
    );

    # Not in the umbriel package, so shaders.toml reaches them relative to its own directory.
    xdg.config.files."umbriel/shaders/kzzzt.glsl".source = ./shaders/kzzzt.glsl;
    xdg.config.files."umbriel/shaders/kzzzt-surge.glsl".source = ./shaders/kzzzt-surge.glsl;
    xdg.config.files."umbriel/shaders/kzzzt-close.glsl".source = ./shaders/kzzzt-close.glsl;
    xdg.config.files."umbriel/shaders/kzzzt-ring.glsl".source = ./shaders/kzzzt-ring.glsl;
  };

  # umbriel resolves its [include] at startup, before noctalia can regenerate the palette on a wiped root
  preservation.preserveAt."/persist".users.${username}.files = [
    ".config/umbriel/noctalia.toml"
  ];
}
