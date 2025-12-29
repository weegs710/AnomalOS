{
  config,
  lib,
  inputs,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.gaming {
    # Anime Game Launchers (Genshin, Honkai, Wuthering Waves, ZZZ)
    programs = {
      anime-game-launcher.enable = false; # Genshin Impact
      honkers-railway-launcher.enable = true; # Honkai: Star Rail
      honkers-launcher.enable = false; # Honkai Impact 3rd
      wavey-launcher.enable = false; # Wuthering Waves
      sleepy-launcher.enable = false; # Zenless Zone Zero
    };

    # Use the aagl nixConfig for additional settings
    nix.settings = inputs.aagl.nixConfig;
  };
}
