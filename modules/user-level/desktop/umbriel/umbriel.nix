{
  config,
  lib,
  only,
  ...
}:
let
  username = config.mySystem.user.name;
  effects = "${config.programs.umbriel.package}/share/umbriel/effects";
in
only.gate { tags = [ "desktop" ]; } {
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

    # the umbriel-shaders plugin rewrites this, noct-s pulls it back
    xdg.config.files."umbriel/noctalia-shaders.toml" = {
      source = ./noctalia-shaders.toml;
      type = "copy";
      clobber = false;
      permissions = "0644";
    };

    # Not in the umbriel package, so shaders.toml reaches them relative to its own directory.
    xdg.config.files."umbriel/shaders/animation/slide-down/effect.toml".source =
      ./shaders/animation/slide-down/effect.toml;
    xdg.config.files."umbriel/shaders/animation/slide-down/shader.glsl".source =
      ./shaders/animation/slide-down/shader.glsl;
  };

  # umbriel resolves its includes at startup, and the umbriel-shaders plugin replaces its file by rename, which a file bind refuses
  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/umbriel"
  ];
}
