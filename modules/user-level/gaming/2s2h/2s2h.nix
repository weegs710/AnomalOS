{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;

  shipHome = ".local/share/2ship2harkinian";

  zip = pkgs.fetchurl {
    name = "2Ship-Battler-Alfa-Linux.zip";
    url = "https://github.com/HarbourMasters/2ship2harkinian/releases/download/5.0.0/2Ship-Battler-Alfa-Linux.zip";
    hash = "sha256-JxizLWCz9PxTmxsWKK9lVPM+LA8cIyNVSFh/a17P700=";
  };

  # the linux release is a zip'd appimage, but wrapType2 wants the bare appimage file
  appimage = pkgs.runCommand "2ship-5.0.0.appimage" { nativeBuildInputs = [ pkgs.unzip ]; } ''
    unzip -p ${zip} 2ship.appimage > $out
  '';

  fhs = pkgs.appimageTools.wrapType2 {
    pname = "2ship-fhs";
    version = "5.0.0";
    src = appimage;
    extraPkgs = _pkgs: [ ];
  };

  # SHIP_HOME is the only lever that pins libultraship's writable dir on linux; unset, the portable build writes beside the read-only store binary
  s2h = pkgs.writeShellScriptBin "2s2h" ''
    export SHIP_HOME="$HOME/${shipHome}"
    mkdir -p "$SHIP_HOME"
    exec ${fhs}/bin/2ship-fhs "$@"
  '';
in
{
  users.users.${username}.packages = [ s2h ];

  hjem.users.${username}.xdg.data.files."2ship2harkinian/2ship2harkinian.json".source = ./2ship2harkinian.json;

  # config.json is hjem-owned and re-laid every boot, so it's kept out of the persist list -- a path can't be both hjem-declared and preservation-persisted without them fighting
  preservation.preserveAt."/persist".users.${username} = {
    directories = [
      "${shipHome}/mods"
      "${shipHome}/saves"
      "${shipHome}/presets"
      "${shipHome}/randomizer"
    ];
    files = [
      "${shipHome}/mm.o2r"
      "${shipHome}/imgui.ini"
    ];
  };
}
