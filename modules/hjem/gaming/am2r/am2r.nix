{
  config,
  lib,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
  gameDir = "/mnt/games/1g1r/AM2R-1.5.5";

  am2r = pkgs.buildFHSEnv {
    name = "am2r";
    multiArch = true;
    multiPkgs =
      p: with p; [
        (pkgs.lib.getLib stdenv.cc.cc)
        libx11
        libxext
        libxrandr
        libxxf86vm
        curl
        libGLU
        libglvnd
        openal
        zlib
      ];
    runScript = "bash -c 'cd ${gameDir} && export LD_LIBRARY_PATH=${gameDir}/lib32:$LD_LIBRARY_PATH && exec ./runner'";
  };
in
{
  users.users.${username}.packages = [ am2r ];

  hjem.users.${username}.xdg.config.files."AM2R/config.ini" = {
    source = ./config.ini;
    type = "copy";
  };

  preservation.preserveAt."/persist".users.${username}.directories = [ ".config/AM2R" ];

  # game binary lives outside the store (copyrighted, on the games drive); patch it in place idempotently
  system.activationScripts.am2rPatch = lib.stringAfter [ "users" ] ''
    if [ -f ${gameDir}/.runner-unwrapped ]; then
      ${pkgs.python3}/bin/python3 ${./patch-am2r-controller.py} ${gameDir}/.runner-unwrapped ${gameDir}/.runner-unwrapped
    fi
  '';
}
