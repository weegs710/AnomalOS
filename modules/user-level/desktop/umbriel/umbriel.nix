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
    xdg.config.files."umbriel/shaders/window/kzzzt/effect.toml".source = ./shaders/window/kzzzt/effect.toml;
    xdg.config.files."umbriel/shaders/window/kzzzt/shader.glsl".source = ./shaders/window/kzzzt/shader.glsl;
    xdg.config.files."umbriel/shaders/border/kzzzt-ring/effect.toml".source = ./shaders/border/kzzzt-ring/effect.toml;
    xdg.config.files."umbriel/shaders/border/kzzzt-ring/shader.glsl".source = ./shaders/border/kzzzt-ring/shader.glsl;
    xdg.config.files."umbriel/shaders/animation/kzzzt-open/effect.toml".source = ./shaders/animation/kzzzt-open/effect.toml;
    xdg.config.files."umbriel/shaders/animation/kzzzt-open/shader.glsl".source = ./shaders/animation/kzzzt-open/shader.glsl;
    xdg.config.files."umbriel/shaders/animation/kzzzt-close/effect.toml".source = ./shaders/animation/kzzzt-close/effect.toml;
    xdg.config.files."umbriel/shaders/animation/kzzzt-close/shader.glsl".source = ./shaders/animation/kzzzt-close/shader.glsl;
  };

  # umbriel resolves its [include] at startup, before noctalia can regenerate the palette on a wiped root
  preservation.preserveAt."/persist".users.${username}.files = [
    ".config/umbriel/noctalia.toml"
  ];
}
