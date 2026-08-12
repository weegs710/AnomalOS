{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;

  fhs = pkgs.appimageTools.wrapType2 {
    pname = "dino-recomp-fhs";
    version = "0.3.0";
    src = pkgs.fetchurl {
      name = "DinosaurPlanetRecompiled-v0.3.0-Linux-x64.AppImage";
      url = "https://github.com/DinosaurPlanetRecomp/dino-recomp/releases/download/v0.3.0/DinosaurPlanetRecompiled-v0.3.0-Linux-x64.AppImage";
      hash = "sha256-s50Iz4lietgXKUXx7Y1jjZ33JPoqtcuHzQ5s2OTLodk=";
    };
    # RT64 is a vulkan renderer and the appimage bundles no loader, so it needs one from the host FHS
    extraPkgs = pkgs: [ pkgs.vulkan-loader ];
  };

  # without APPIMAGE set the binary can't locate its bundled assets
  dino-recomp = pkgs.writeShellScriptBin "dino-recomp" ''
    export APPIMAGE=1
    exec ${fhs}/bin/dino-recomp-fhs "$@"
  '';
in
{
  users.users.${username}.packages = [ dino-recomp ];

  hjem.users.${username}.xdg.config.files."DinoPlanetRecompiled/graphics.json".source = ./graphics.json;

  preservation.preserveAt."/persist".users.${username} = {
    directories = [
      ".config/DinoPlanetRecompiled/mods"
      ".config/DinoPlanetRecompiled/mod_config"
      ".config/DinoPlanetRecompiled/saves"
    ];
    files = [
      ".config/DinoPlanetRecompiled/dino.z64"
      ".config/DinoPlanetRecompiled/general.json"
      ".config/DinoPlanetRecompiled/controls.json"
      ".config/DinoPlanetRecompiled/sound.json"
    ];
  };
}
